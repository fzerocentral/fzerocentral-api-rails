class Chart < ApplicationRecord
  belongs_to :chart_group
  belongs_to :chart_type
  has_many :records
end
