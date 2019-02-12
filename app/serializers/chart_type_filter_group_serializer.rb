class ChartTypeFilterGroupSerializer < ActiveModel::Serializer
  attributes :id, :show_by_default, :order_in_chart_type
  has_one :chart_type
  has_one :filter_group
end
