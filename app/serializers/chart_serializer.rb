class ChartSerializer < ActiveModel::Serializer
  attributes :name
  belongs_to :chart_group
end
