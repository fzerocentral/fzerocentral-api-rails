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

  validates :name, presence: true
  validates :name, length: { maximum: 100 }
  validates :name, uniqueness: {
    scope: :filter_group, case_sensitive: false,
    message: "'%{value}' is already taken by another filter in this group" \
      " (case insensitive)" }

  validates :numeric_value, presence: true,
    if: :group_is_numeric?
  validates :numeric_value, numericality: { only_integer: true },
    if: :numeric_value_is_present?

  validates :usage_type, presence: true
  validates :usage_type, inclusion: {
    in: %w(choosable implied),
    message: "should be either 'choosable' or 'implied', not '%{value}'" }

  validates :filter_group, presence: true

  before_destroy do
    cannot_delete_with_records
    cannot_delete_with_links
    throw :abort if errors.present?
  end

  def cannot_delete_with_links
    if implications_received.any? || implications_made.any?
      errors.add(:base, "Cannot delete filter; it has existing implications")
    end
  end
  def cannot_delete_with_records
    if record_filters.any?
      errors.add(
        :base, "Cannot delete filter; it's used in one or more records")
    end
  end
  def group_is_numeric?
    if filter_group.nil?
      false
    else
      filter_group.kind == 'numeric'
    end
  end
  def numeric_value_is_present?
    numeric_value.present?
  end
end
