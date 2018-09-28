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

    sort_method = params.fetch(:sort, 'date')
    if sort_method == 'date'
      # Latest date first
      @records = @records.order(achieved_at: :desc)
    elsif sort_method == 'value'
      # Best value first
      if chart
        @records = @records.order(
          value: get_chart_order_direction(chart.chart_type))
      else
        # Ordering by value across charts is weird, but we'll allow it,
        # defaulting to ascending
        @records = @records.order(value: :asc)
      end
    end

    if params.key?(:ranked_entity)
      @records = create_ranking(@records, params[:ranked_entity])
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

    def create_ranking(unranked_records, ranked_entity)
      # Keep only the first record from each ranked_entity ('user' or 'chart'),
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
        if ranked_entity == 'user'
          this_record_entity = record.user_id
        elsif ranked_entity == 'chart'
          this_record_entity = record.chart_id
        end

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
end
