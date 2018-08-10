class Chart < ApplicationRecord
  belongs_to :chart_group
  has_many :records
end
