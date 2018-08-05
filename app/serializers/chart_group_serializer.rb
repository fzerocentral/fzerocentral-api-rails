class ChartGroupSerializer < ActiveModel::Serializer
  attributes :name
  belongs_to :game
  belongs_to :parent_group
  has_many :child_groups
  has_many :charts
end
