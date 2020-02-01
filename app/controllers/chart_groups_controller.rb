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
      
      # Filter by parent, and return the child groups in order
      @chart_groups = @chart_groups\
        .where(parent_group_id: parent_group_id)\
        .order('order_in_parent ASC')
    end

    # This will include all child groups and charts within this chart group,
    # so that the chart hierarchy can be retrieved without needing N+1
    # queries to the DB.
    # This implementation effectively hard-codes the number of levels of group
    # nesting that we support, though.
    @chart_groups = @chart_groups.includes(
      :charts, :child_groups, :game, :parent_group,
      charts: [:chart_group, :chart_type],
      child_groups: [
        :charts, :child_groups, :game, :parent_group,
        charts: [:chart_group, :chart_type],
        child_groups: [
          :charts, :child_groups, :game, :parent_group,
          charts: [:chart_group, :chart_type],
          child_groups: [
            :charts, :game, :parent_group,
            charts: [:chart_group, :chart_type],
          ],
        ],
      ],
    )

    # This will include all child groups and charts within this chart group,
    # so that the chart hierarchy can be listed without needing further
    # queries to this API.
    # This implementation effectively hard-codes the number of levels of group
    # nesting that we support, though.
    render json: @chart_groups,
           include: 'child_groups,'\
                    'child_groups.charts,'\
                    'child_groups.child_groups,'\
                    'child_groups.child_groups.charts,'\
                    'child_groups.child_groups.child_groups,'\
                    'child_groups.child_groups.child_groups.charts'
  end

  # GET /chart_groups/1
  def show
    render json: @chart_group,
           include: 'charts,'\
                    'child_groups.charts'
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
