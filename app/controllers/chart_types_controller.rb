class ChartTypesController < ApplicationController
  before_action :set_chart_type, only: [:show, :update, :destroy]

  # GET /chart_types
  def index
    @chart_types = ChartType.all

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
      params.require(:chart_type).permit(:name, :format_spec, :order_ascending, :game_id)
    end
end