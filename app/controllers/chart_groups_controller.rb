class ChartGroupsController < ApplicationController
  before_action :set_chart_group, only: [:show, :update, :destroy]

  # GET /chart_groups
  def index
    @chart_groups = ChartGroup.all

    # Can filter by game
    if params.key?(:game_id)
      @chart_groups = @chart_groups.where(game_id: params[:game_id])
    end

    # Can filter by parent
    if params.key?(:parent_group_id)
      if params[:parent_group_id] == ''
        # Blank parent means this is a top level group for the
        # group's game
        parent_group_id = nil
      else
        parent_group_id = params[:parent_group_id]
      end
      @chart_groups = @chart_groups.where(parent_group_id: parent_group_id)
    end

    render json: @chart_groups
  end

  # GET /chart_groups/1
  #
  # This will include all child groups and charts within this chart group,
  # so that the chart hierarchy can be listed without needing further queries.
  # Though, including this without being asked (i.e. without include args)
  # might be considered non-standard for JSON API.
  def show
    render json: @chart_group,
           include: 'charts,'\
                    'child_groups.charts,'\
                    'child_groups.child_groups.charts,'\
                    'child_groups.child_groups.child_groups.charts'
  end

  # POST /chart_groups
  def create
    @chart_group = ChartGroup.new(chart_group_params)

    if @chart_group.save
      render json: @chart_group, status: :created, location: @chart_group
    else
      render json: @chart_group.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /chart_groups/1
  def update
    if @chart_group.update(chart_group_params)
      render json: @chart_group
    else
      render json: @chart_group.errors, status: :unprocessable_entity
    end
  end

  # DELETE /chart_groups/1
  def destroy
    @chart_group.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chart_group
      @chart_group = ChartGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def chart_group_params
      params.require(:chart_group).permit(:name, :game_id, :parent_group_id, :order_in_parent)
    end
end
