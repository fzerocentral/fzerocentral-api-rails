class FilterImplicationLinkSerializer < ActiveModel::Serializer
  attributes :id
  has_one :implying_filter
  has_one :implied_filter
end
