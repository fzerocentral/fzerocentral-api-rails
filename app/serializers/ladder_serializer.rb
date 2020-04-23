class LadderSerializer < ActiveModel::Serializer
  attributes :id, :name, :kind, :filter_spec, :order_in_game_and_kind
  belongs_to :chart_group
  belongs_to :game
end
