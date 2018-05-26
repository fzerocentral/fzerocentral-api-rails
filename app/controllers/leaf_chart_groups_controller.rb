class LeafChartGroupsController < ApplicationController
  before_action :set_leaf_chart_group, only: [:show, :update, :destroy]

  # GET /leaf_chart_groups
  def index
    @leaf_chart_groups = LeafChartGroup.all

    render json: @leaf_chart_groups
  end

  # GET /leaf_chart_groups/1
  def show
    render json: @leaf_chart_group
  end

  # POST /leaf_chart_groups
  def create
    @leaf_chart_group = LeafChartGroup.new(leaf_chart_group_params)

    if @leaf_chart_group.save
      render json: @leaf_chart_group, status: :created, location: @leaf_chart_group
    else
      render json: @leaf_chart_group.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /leaf_chart_groups/1
  def update
    if @leaf_chart_group.update(leaf_chart_group_params)
      render json: @leaf_chart_group
    else
      render json: @leaf_chart_group.errors, status: :unprocessable_entity
    end
  end

  # DELETE /leaf_chart_groups/1
  def destroy
    @leaf_chart_group.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_leaf_chart_group
      @leaf_chart_group = LeafChartGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def leaf_chart_group_params
      params.require(:leaf_chart_group).permit(:type)
    end
end
