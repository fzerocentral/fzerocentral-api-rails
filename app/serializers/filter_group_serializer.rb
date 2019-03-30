class FilterGroupSerializer < ActiveModel::Serializer
  # `kind` should either be 'select' or 'numeric'
  attributes :id, :name, :description, :kind

  # m2m attributes
  attributes :show_by_default
end
