class RecordSerializer < ActiveModel::Serializer
  attributes :value
  attributes :achieved_at

  # Virtual attributes
  attributes :is_improvement
  attributes :rank
  attributes :value_display

  belongs_to :chart
  belongs_to :user
  has_many :filters, through: :record_filters
end
