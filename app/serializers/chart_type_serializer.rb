class ChartTypeSerializer < ActiveModel::Serializer
  attributes :id, :name, :format_spec, :order_ascending
  has_one :game
end
