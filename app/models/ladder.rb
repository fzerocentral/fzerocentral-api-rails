class Ladder < ApplicationRecord
  belongs_to :chart_group
  belongs_to :game

  validates :name, presence: true
  validates :name, length: { maximum: 200 }

  validates :kind, presence: true
  validates :kind, inclusion: {
    in: %w(main side),
    message: "should be either 'main' or 'side', not '%{value}'" }

  validates :filter_spec, length: { maximum: 200 }

  validates :chart_group, presence: true

  validates :game, presence: true

  validates :order_in_game_and_kind, uniqueness: {
    scope: [:game, :kind],
    message: "'%{value}' is already taken by another ladder of this game and kind" }
end
