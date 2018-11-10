class Filter < ApplicationRecord
  belongs_to :filter_group

  # Many-to-many self-join
  # https://stackoverflow.com/a/25493403/
  has_many :implications_received, foreign_key: :implied_filter_id, class_name: "FilterImplication"
  has_many :implying_filters, through: :implications_received, source: :implying_filter
  has_many :implications_made, foreign_key: :implying_filter_id, class_name: "FilterImplication"
  has_many :implied_filters, through: :implications_made, source: :implied_filter

  has_many :record_filters
  has_many :records, through: :record_filters
end
