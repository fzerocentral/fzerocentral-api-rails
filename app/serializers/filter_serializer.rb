class FilterSerializer < ActiveModel::Serializer
  attributes :id, :name, :order_in_group, :numeric_value
  belongs_to :filter_group
end
