class CreateChartGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :chart_groups do |t|
      t.string :name
      t.references :game, foreign_key: true
      t.references :chart_group, foreign_key: true, null: true

      t.timestamps
    end
  end
end
