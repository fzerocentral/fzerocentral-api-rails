class CreateLeafChartGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :leaf_chart_groups do |t|
      t.references :chart_group, foreign_key: true, null: true

      t.timestamps
    end
  end
end
