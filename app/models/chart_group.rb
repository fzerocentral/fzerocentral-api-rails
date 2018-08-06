class ChartGroup < ApplicationRecord
  belongs_to :game

  # A game's chart groups are arranged in a hierarchy.
  # Top-level chart groups won't have a parent, hence use of `optional`.
  belongs_to :parent_group, class_name: "ChartGroup", optional: true
  has_many :child_groups, -> { order('order_in_parent ASC') }, class_name: "ChartGroup", foreign_key: "parent_group_id"

  # Only bottom-level chart groups have charts.
  # In other words, it's impossible for a chart group to have non-empty
  # child_groups AND non-empty charts.
  has_many :charts, -> { order('order_in_group ASC') }
end
