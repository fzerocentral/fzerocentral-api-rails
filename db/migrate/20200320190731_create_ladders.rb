class CreateLadders < ActiveRecord::Migration[6.0]
  def change
    create_table :ladders do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.string :filter_spec, null: false

      # Specifies the charts the ladder applies to.
      t.references :chart_group, null: false, foreign_key: true
      # Makes usage of the order field more straightforward.
      t.references :game, null: false, foreign_key: true

      # Defines ordering of ladders in a particular game, of a particular kind.
      t.integer :order_in_game_and_kind, null: false

      t.timestamps
    end

    add_index :ladders, [:game_id, :kind, :order_in_game_and_kind], unique: true
  end
end
