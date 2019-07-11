class FiltersController < ApplicationController
  before_action :set_filter, only: [:show, :update, :destroy]

  # GET /filters
  def index
    if params.key?(:filter_ids)
      # Comma separated IDs like 1,3,9,24
      @filters = Filter.find(params[:filter_ids].split(','))
    elsif params.key?(:filter_group_id)
      filter_group = FilterGroup.find(params[:filter_group_id])
      @filters = filter_group.filters

      if params.key?(:usage_type)
        @filters = @filters.where(usage_type: params[:usage_type])
      end

      @filters = @filters.order(name: :asc)
    else
      @filters = Filter.all
    end

    paginate json: @filters
  end

  # GET /filters/1
  def show
    render json: @filter
  end

  # POST /filters
  def create
    @filter = Filter.new(filter_params)

    if @filter.save
      render json: @filter, status: :created, location: @filter
    else
      render_resource_with_validation_errors(@filter)
    end
  end

  # PATCH/PUT /filters/1
  def update
    if @filter.update(filter_params)
      render json: @filter
    else
      render_resource_with_validation_errors(@filter)
    end
  end

  # DELETE /filters/1
  def destroy
    if !@filter.destroy
      render_resource_with_validation_errors(@filter)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_filter
      @filter = Filter.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def filter_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters. `only` is applied before `key_transform`, so we
        # must specify `'filter-group'` instead of `:filter_group`.
        only: [:name, 'filter-group', 'numeric-value', 'usage-type'],
        # This transforms kebab-case attributes from the JSON API request to
        # snake_case.
        key_transform: :underscore)
    end
end
