# https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/configuration_options.md
# https://www.simplify.ba/articles/2016/06/18/creating-rails5-api-only-application-following-jsonapi-specification/
# https://github.com/rails-api/active_model_serializers/issues/1027#issuecomment-247605393 (register_jsonapi_renderer)
require 'active_model_serializers/register_jsonapi_renderer'

ActiveModel::Serializer.config.adapter = :json_api
