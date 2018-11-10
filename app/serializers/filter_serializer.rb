class FilterSerializer < ActiveModel::Serializer
  attributes :id, :name, :numeric_value
  belongs_to :filter_group
end
