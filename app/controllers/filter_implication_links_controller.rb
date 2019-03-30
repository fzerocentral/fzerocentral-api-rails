class FilterImplicationLinksController < ApplicationController
  before_action :set_filter_implication_link, only: [:show, :update, :destroy]

  # GET /filter_implication_links
  def index
    if params.key?(:filter_group_id)
      # Implying filter should be in this filter group.
      # (Filters of different filter groups should never be linked, so this
      # should also mean the implied filter is in this group.)
      @links = FilterImplicationLink.joins(:implying_filter) \
        .where(filters: {filter_group_id: params[:filter_group_id]})

      # Order by implying filter's name, then implied filter's name.
      # Unfortunately, using table aliases with joins in ActiveRecord seems
      # to require raw SQL or Arel syntax. We've picked raw SQL here.
      @links = @links \
        .joins("INNER JOIN filters AS implying_filters ON implying_filters.id = filter_implication_links.implying_filter_id") \
        .joins("INNER JOIN filters AS implied_filters ON implied_filters.id = filter_implication_links.implied_filter_id") \
        .order('implying_filters.name ASC') \
        .order('implied_filters.name ASC')

      render json: @links
    else
      render_json_error("Must specify a filter_group_id", :bad_request)
    end
  end

  # GET /filter_implication_links/1
  def show
    render json: @link
  end

  # POST /filter_implication_links
  def create
    @link = FilterImplicationLink.new(link_params)

    if @link.save
      render json: @link, status: :created, location: @link
    else
      render json: @link.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /filter_implication_links/1
  def update
    if @link.update(link_params)
      render json: @link
    else
      render json: @link.errors, status: :unprocessable_entity
    end
  end

  # DELETE /filter_implication_links/1
  def destroy
    @link.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_filter_implication_link
      @link = FilterImplicationLink.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def link_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(
        params,
        # Strong parameters. `only` is applied before `key_transform`, so we
        # must specify `'implying-filter'` instead of `:implying_filter`.
        only: ['implying-filter', 'implied-filter'],
        # This transforms kebab-case attributes from the JSON API request to
        # snake_case.
        key_transform: :underscore)
    end

    # Render an error, following the JSON API standard.
    def render_json_error(message, status)
      render(
        json: {errors: [{detail: message}]},
        status: status)
    end
end
