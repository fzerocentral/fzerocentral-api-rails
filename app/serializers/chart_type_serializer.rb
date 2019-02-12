class ChartTypeSerializer < ActiveModel::Serializer
  attributes :id, :name, :format_spec, :order_ascending
  has_one :game
  has_many :filter_groups, through: :chart_type_filter_groups
end
