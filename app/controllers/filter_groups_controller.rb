class FilterGroupsController < ApplicationController
  before_action :set_filter_group, only: [:show, :update, :destroy]

  # GET /filter_groups
  def index
    chart_type = nil

    if params.key?(:chart_type_id)
      chart_type = ChartType.find(params[:chart_type_id])
      @filter_groups = chart_type.filter_groups
    elsif params.key?(:chart_id)
      chart = Chart.find(params[:chart_id])
      chart_type = chart.chart_type
      @filter_groups = chart_type.filter_groups
    elsif params.key?(:record_id)
      record = Record.find(params[:record_id])
      chart_type = record.chart.chart_type
      @filter_groups = chart_type.filter_groups
    else
      @filter_groups = FilterGroup.all
    end

    if chart_type
      @filter_groups.each do |filter_group|
        ctfg = ChartTypeFilterGroup.find_by(
          chart_type: chart_type, filter_group: filter_group)
        filter_group.show_by_default = ctfg.show_by_default
      end
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
      params.require(:filter_group).permit(:name, :description, :kind)
    end
end
