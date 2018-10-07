class RecordsController < ApplicationController
  before_action :set_record, only: [:show, :update, :destroy]

  # GET /records
  def index
    @records = Record.all
    chart = nil

    if params.key?(:chart_id)
      @records = @records.where(chart_id: params[:chart_id])
      chart =  Chart.find(params[:chart_id])
    end
    if params.key?(:user_id)
      @records = @records.where(user_id: params[:user_id])
    end

    sort_method = params.fetch(:sort, 'date_submitted')
    if sort_method == 'date_submitted'
      # Latest date first. Date granularity is limited, so ties are possible.
      # Therefore we do a secondary ordering by record ID, which makes the
      # order repeatable, and also orders by creation time in most cases.
      @records = @records.order(created_at: :desc, id: :desc)
    elsif sort_method == 'date_achieved'
      # Latest date first. The secondary ordering by record ID makes the
      # result order repeatable.
      @records = @records.order(achieved_at: :desc, id: :desc)
    elsif sort_method == 'value'
      # Best value first
      if chart
        value_order_direction = get_chart_order_direction(chart.chart_type)
      elsif @records.length > 0
        # Ordering by value across charts assumes all of these charts use the
        # same order. So we'll just take the order of any record's chart.
        value_order_direction = get_chart_order_direction(@records[0].chart.chart_type)
      else
        # We don't even have any records to get a chart from. Well, if there
        # are no records, the order doesn't matter anyway, so we arbitrarily
        # pick asc.
        value_order_direction = :asc
      end
      # Tiebreak by earliest achieved, followed by earliest submitted
      @records = @records.order(value: value_order_direction, achieved_at: :asc, id: :asc)
    else
      render_json_error("Unrecognized sort method: #{sort_method}", :bad_request)
      return
    end

    ranked_entity = params.fetch(:ranked_entity, nil)
    if ranked_entity != nil
      if ranked_entity == 'user'
        get_ranked_entity = ->(record) { record.user.id }
      elsif ranked_entity == 'chart'
        get_ranked_entity = ->(record) { record.chart.id }
      else
        render_json_error("Unrecognized ranked_entity option: #{ranked_entity}", :bad_request)
        return
      end
      @records = create_ranking(@records, get_ranked_entity)
    end

    # What to do with improvements among the set of records over time:
    # flag which ones are improvements or not, or filter out the
    # non-improvements.
    # Used for a user's PB history, or WR history.
    improvements_option = params.fetch(:improvements, nil)
    not_sorting_by_date = !sort_method.include?('date')
    if improvements_option != nil and (not_sorting_by_date or chart == nil)
      render_json_error("To use the 'improvements' option, you must sort by date, and you must specify a chart_id.", :bad_request)
      return
    end

    if improvements_option == 'flag'
      flag_improvements(@records, chart.chart_type)
    elsif improvements_option == 'filter'
      @records = filter_to_improvements_only(@records, chart.chart_type)
    elsif improvements_option != nil
      render_json_error("Unrecognized improvements option: #{improvements_option}", :bad_request)
      return
    end

    # Add human-readable strings of the record values
    add_record_displays(@records)

    render json: @records
  end

  # GET /records/1
  def show
    render json: @record
  end

  # POST /records
  def create
    @record = Record.new(record_params)

    if @record.save
      render json: @record, status: :created, location: @record
    else
      render json: @record.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /records/1
  def update
    if @record.update(record_params)
      render json: @record
    else
      render json: @record.errors, status: :unprocessable_entity
    end
  end

  # DELETE /records/1
  def destroy
    @record.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Record.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def record_params
      params.require(:record).permit(:value, :achieved_at, :chart_id, :user_id)
    end

    def get_chart_order_direction(chart_type)
      if chart_type.order_ascending
        return :asc
      else
        return :desc
      end
    end

    # If value is a better record than best_so_far, return true. If worse
    # or tied, return false. "better"/"worse" is determined by the chart_type.
    def record_is_improvement(value, best_so_far, chart_type)
      if best_so_far == nil
        return true
      elsif chart_type.order_ascending
        return value < best_so_far
      else
        # Descending
        return value > best_so_far
      end
    end

    def create_ranking(unranked_records, get_ranked_entity)
      # Keep only the first record from each ranked_entity (e.g. each user),
      # and assign rank numbers to the remaining records, accounting for
      # tied values.
      # unranked_records should already be sorted as desired.
      seen_entities = Set.new
      current_rank = 0
      previous_record_count = 0
      previous_value = nil
      ranked_records = []

      unranked_records.each do |record|
        # Keep only the best record from each entity. They are already sorted
        # in the desired order at this point (e.g. best to worst values), and
        # from here we grab the first one for each user.
        #
        # Ideally the database would do this filtering for us, but DISTINCT ON
        # doesn't seem to be flexible enough... (could be wrong about that)
        this_record_entity = get_ranked_entity.call(record)
        if seen_entities.include?(this_record_entity)
          # Not the first record from this entity. Ignore.
          next
        end

        if record.value != previous_value
          # Not a tie with the previous record
          current_rank = previous_record_count + 1
        end
        record.rank = current_rank
        previous_record_count += 1
        previous_value = record.value

        ranked_records.push(record)
        seen_entities.add(this_record_entity)
      end

      return ranked_records
    end

    def flag_improvements(records, chart_type)
      # At this point we know the records are sorted from latest date first.
      # Iterate in reverse, from earliest date first, and figure out which
      # records are improvements over all previous records.
      # Flag each record as an improvement or not.
      best_so_far = nil
      records.reverse_each do |record|
        if record_is_improvement(record.value, best_so_far, chart_type)
          best_so_far = record.value
          record.is_improvement = true
        else
          record.is_improvement = false
        end
      end
    end

    def filter_to_improvements_only(records, chart_type)
      improvements_only = []
      best_so_far = nil
      # While looking for improvements, iterate from earliest date first.
      records.reverse_each do |record|
        if record_is_improvement(record.value, best_so_far, chart_type)
          best_so_far = record.value
          # Add to array start, to construct an array which starts from
          # latest date first.
          improvements_only.unshift(record)
        end
      end
      return improvements_only
    end

    def add_record_displays(records)
      # Add value_display attribute to each record. This attribute is the
      # human-readable string of the record value, such as 1'23"456 instead of
      # 123456.
      # Modifies records in-place.

      records.each do |record|
        # Order of the hashes determines both rank (importance of this
        # number relative to the others) AND position-order in the string.
        # Can't think of any examples where those would need to be different.
        #
        # Since format_spec is loaded from JSON, the hash keys are strings like
        # 'multiplier', not colon identifiers like :multiplier.
        format_spec = record.chart.chart_type.format_spec
        total_multiplier = 1
        format_spec.reverse.each do |spec_item|
          total_multiplier = total_multiplier * spec_item.fetch('multiplier', 1)
          spec_item['total_multiplier'] = total_multiplier
        end

        remaining_value = record.value
        value_display = ""
        format_spec.each do |spec_item|
          item_value = remaining_value / spec_item['total_multiplier']
          remaining_value = remaining_value % spec_item['total_multiplier']

          number_format = '%'
          if spec_item.key?('digits')
            number_format += '0' + spec_item['digits'].to_s
          end
          number_format += 'd'

          value_display += \
            (number_format % item_value) + spec_item.fetch('suffix', '')
        end
        record.value_display = value_display
      end
    end

    # Render an error, following the JSON API standard.
    def render_json_error(message, status)
      render(
        json: {errors: [{detail: message}]},
        status: status)
    end
end
