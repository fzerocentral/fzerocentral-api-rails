class RecordsController < ApplicationController
  before_action :set_record, only: [:show, :update, :destroy]

  # GET /records
  def index
    if params.key?(:chart_id)

      # Show record rankings for a chart.
      all_records = Record\
        # Records in this chart
        .where(chart_id: params[:chart_id])\
        # Lowest first (should make asc vs. desc dependent on Chart Type later)
        .order(value: :asc)

      seen_user_ids = Set.new
      current_rank = 0
      previous_record_count = 0
      previous_value = nil
      @records = []

      all_records.each do |record|
        # Keep only the best record from each user. They are already sorted from
        # best to worst at this point, so we grab the first one for each user.
        #
        # Ideally the database would do this filtering for us, but DISTINCT ON
        # doesn't seem to be flexible enough... (could be wrong about that)
        if seen_user_ids.include?(record.user_id)
          next
        end

        if record.value != previous_value
          # Not a tie with the previous record
          current_rank = previous_record_count + 1
        end
        record.rank = current_rank
        @records.push(record)

        seen_user_ids.add(record.user_id)
        previous_record_count += 1
        previous_value = record.value
      end
    else
      @records = Record.all
    end

    # Add additional info to each record.

    # Order of the hashes currently determines both rank (importance of this
    # number relative to the others) AND position-order in the string.
    # Currently can't think of any examples where those would be separate.
    display_spec = [
      {multiplier: 60, suffix: "'"},
      {multiplier: 1000, suffix: '"', digits: 2},
      {digits: 3},
    ]
    total_multiplier = 1
    display_spec.reverse.each do |spec_item|
      total_multiplier = total_multiplier * spec_item.fetch(:multiplier, 1)
      spec_item[:total_multiplier] = total_multiplier
    end

    @records.each do |record|
      remaining_value = record.value
      value_display = ""
      display_spec.each do |spec_item|
        item_value = remaining_value / spec_item[:total_multiplier]
        remaining_value = remaining_value % spec_item[:total_multiplier]

        number_format = '%'
        if spec_item.key?(:digits)
          number_format += '0' + spec_item[:digits].to_s
        end
        number_format += 'd'

        value_display += \
          (number_format % item_value) + spec_item.fetch(:suffix, '')
      end
      record.value_display = value_display
    end

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
end
