class Record < ApplicationRecord
  belongs_to :chart
  belongs_to :user

  attr_accessor :rank
  attr_accessor :value_display
end