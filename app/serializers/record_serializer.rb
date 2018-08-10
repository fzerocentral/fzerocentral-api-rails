class RecordSerializer < ActiveModel::Serializer
  attributes :value

  # Virtual attributes
  attributes :rank
  attributes :value_display

  belongs_to :chart
  belongs_to :user
end
