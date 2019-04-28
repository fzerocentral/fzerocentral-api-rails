class FilterSerializer < ActiveModel::Serializer
  attributes :id, :name, :numeric_value, :usage_type
  belongs_to :filter_group
end
