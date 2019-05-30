class ApplicationController < ActionController::API
  private
    def render_resource_with_errors(resource, status)
      render json: resource, status: status, adapter: :json_api,
             serializer: ActiveModel::Serializer::ErrorSerializer
    end

    def render_resource_with_validation_errors(resource)
      # This can include model validation errors, like a required field being
      # missing in a creation request.
      #
      # Some sources say to use 422 Unprocessable Entity instead of 400 Bad
      # Request for semantic errors like these, but that reasoning appears
      # to be largely based on the old RFC 2616 which constrained 400 usage
      # to a narrow definition. RFC 7231 explicitly obsoletes 2616 and expands
      # 400 to cover client errors in general.
      # https://softwareengineering.stackexchange.com/a/342896/221516
      render_resource_with_errors(resource, :bad_request)
    end

    def render_general_error(detail, status)
      # Can include GET/read errors, for example, where there's not a readily
      # obvious single resource to attach the errors to.
      render json: {'errors': [{'detail': detail}]}, status: status
    end

    def render_general_validation_error(detail)
      render_general_error(detail, :bad_request)
    end
end
