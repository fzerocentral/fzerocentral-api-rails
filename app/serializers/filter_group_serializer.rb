class FilterGroupSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :kind

  # m2m attributes
  attributes :show_by_default
end
