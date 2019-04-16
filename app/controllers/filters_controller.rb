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

      chosen_only = params[:chosen_only].present?
      if chosen_only
        # Chosen filters only, not implied ones. Get the filters which have an
        # empty set of implications_received.
        # https://stackoverflow.com/a/39410256
        @filters =  @filters.left_outer_joins(:implications_received)\
          .where(filter_implications: {id: nil})
      end

      @filters = @filters.order(name: :asc)
    else
      @filters = Filter.all
    end

    render json: @filters
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
      render json: @filter.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /filters/1
  def update
    if @filter.update(filter_params)
      render json: @filter
    else
      render json: @filter.errors, status: :unprocessable_entity
    end
  end

  # DELETE /filters/1
  def destroy
    @filter.destroy
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
        only: [:name, 'filter-group', 'numeric-value'],
        # This transforms kebab-case attributes from the JSON API request to
        # snake_case.
        key_transform: :underscore)
    end
end
