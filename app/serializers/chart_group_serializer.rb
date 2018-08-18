class ChartGroupSerializer < ActiveModel::Serializer
  attributes :name, :show_charts_together
  belongs_to :game
  belongs_to :parent_group
  has_many :child_groups
  has_many :charts
end
