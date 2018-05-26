class CreateCharts < ActiveRecord::Migration[5.1]
  def change
    create_table :charts do |t|
      t.string :name
      t.references :leaf_chart_group, foreign_key: true

      t.timestamps
    end
  end
end
