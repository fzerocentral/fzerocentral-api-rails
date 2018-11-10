class Record < ApplicationRecord
  belongs_to :chart
  belongs_to :user
  has_many :record_filters
  has_many :filters, through: :record_filters

  attr_accessor :is_improvement
  attr_accessor :rank
  attr_accessor :value_display
end

class RecordFilter < ApplicationRecord
  belongs_to :record
  belongs_to :filter
end
