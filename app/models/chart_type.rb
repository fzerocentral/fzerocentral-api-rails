class ChartType < ApplicationRecord
  belongs_to :game
  has_many :charts
  has_many :chart_type_filter_groups
  has_many :filter_groups, through: :chart_type_filter_groups
end
