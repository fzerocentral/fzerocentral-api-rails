class FilterImplicationsController < ApplicationController

  # GET /filter_implications
  def index
    if params.key?(:implying_filter_id)
      @implications = FilterImplication.where(
        implying_filter_id: params[:implying_filter_id])
      @implications = \
        @implications.joins(:implied_filter).order('filters.name ASC')
    elsif params.key?(:implied_filter_id)
      @implications = FilterImplication.where(
        implied_filter_id: params[:implied_filter_id])
      @implications = \
        @implications.joins(:implying_filter).order('filters.name ASC')
    else
      render_json_error(
        "Missing parameters",
        "Must specify an implying_filter_id or implied_filter_id.",
        :unprocessable_entity)
      return
    end

    paginate json: @implications, per_page: 10
  end

  private
    # Render an error, following the JSON API standard.
    def render_json_error(title, message, status)
      render(
        json: {errors: [{title: title, detail: message}]},
        status: status)
    end
end
