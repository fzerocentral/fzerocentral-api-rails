class FilterGroupsController < ApplicationController
  before_action :set_filter_group, only: [:show, :update, :destroy]

  # GET /filter_groups
  def index
    if params.key?(:chart_type_id)
      if params[:chart_type_id] == ''
        # Get orphaned filter groups
        @filter_groups =
          FilterGroup.all.left_outer_joins(:chart_type_filter_groups)
          .where(chart_type_filter_groups: {id: nil})
      else
        chart_type = ChartType.find(params[:chart_type_id])
        @filter_groups = filter_groups_of_chart_type(chart_type)
      end
    elsif params.key?(:chart_id)
      chart = Chart.find(params[:chart_id])
      @filter_groups = filter_groups_of_chart_type(chart.chart_type)
    elsif params.key?(:record_id)
      record = Record.find(params[:record_id])
      @filter_groups = filter_groups_of_chart_type(record.chart.chart_type)
    elsif params.key?(:game_id)
      game = Game.find(params[:game_id])
      @filter_groups = \
        FilterGroup.joins(:chart_types).where(chart_types: { game: game })
    else
      @filter_groups = FilterGroup.all
    end

    render json: @filter_groups
  end

  # GET /filter_groups/1
  def show
    render json: @filter_group
  end

  # POST /filter_groups
  def create
    @filter_group = FilterGroup.new(filter_group_params)

    if @filter_group.save
      render json: @filter_group, status: :created, location: @filter_group
    else
      render json: @filter_group.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /filter_groups/1
  def update
    if @filter_group.update(filter_group_params)
      render json: @filter_group
    else
      render json: @filter_group.errors, status: :unprocessable_entity
    end
  end

  # DELETE /filter_groups/1
  def destroy
    @filter_group.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_filter_group
      @filter_group = FilterGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def filter_group_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters.
        only: [:name, :description, :kind],
        key_transform: :underscore)
    end

    def filter_groups_of_chart_type(chart_type)
      # Get the chart type's filter groups in order
      ordered_fg_ids = ChartTypeFilterGroup \
        .where(chart_type: chart_type) \
        .order(order_in_chart_type: :asc) \
        .pluck('filter_group_id')
      filter_groups = FilterGroup.find(ordered_fg_ids)

      # Add show_by_default field from the m2m table
      filter_groups.each do |filter_group|
        ctfg = ChartTypeFilterGroup.find_by(
          chart_type: chart_type, filter_group: filter_group)
        filter_group.show_by_default = ctfg.show_by_default
      end

      return filter_groups
    end
end
