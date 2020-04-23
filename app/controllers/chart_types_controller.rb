class ChartTypesController < ApplicationController
  before_action :set_chart_type, only: [:show, :update, :destroy]

  # GET /chart_types
  def index
    if params.key?(:filter_group_id)
      filter_group = FilterGroup.find(params[:filter_group_id])
      @chart_types = filter_group.chart_types
    else
      @chart_types = ChartType.all
    end

    if params.key?(:game_id)
      @chart_types = @chart_types.where(game_id: params[:game_id])
    end

    render json: @chart_types
  end

  # GET /chart_types/1
  def show
    render json: @chart_type
  end

  # POST /chart_types
  def create
    @chart_type = ChartType.new(chart_type_params)

    if @chart_type.save
      render json: @chart_type, status: :created, location: @chart_type
    else
      render json: @chart_type.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /chart_types/1
  def update
    if @chart_type.update(chart_type_params)
      render json: @chart_type
    else
      render json: @chart_type.errors, status: :unprocessable_entity
    end
  end

  # DELETE /chart_types/1
  def destroy
    @chart_type.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chart_type
      @chart_type = ChartType.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def chart_type_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters.
        only: [:name, 'format-spec', 'order-ascending', :game],
        key_transform: :underscore)
    end
end
