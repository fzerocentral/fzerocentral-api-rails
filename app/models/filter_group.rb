class FilterGroup < ApplicationRecord
  has_many :filters
  has_many :chart_type_filter_groups
  has_many :chart_types, through: :chart_type_filter_groups

  attr_accessor :show_by_default
end

class FilterGroupMembership < ApplicationRecord
  belongs_to :filter_group
  belongs_to :filter
end
