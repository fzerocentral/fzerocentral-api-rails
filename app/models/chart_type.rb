class ChartType < ApplicationRecord
  belongs_to :game
  has_many :charts
end
