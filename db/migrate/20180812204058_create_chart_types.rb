class CreateChartTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :chart_types do |t|
      t.string :name
      t.json :format_spec
      t.boolean :order_ascending
      t.references :game, foreign_key: true

      t.timestamps
    end
    
    # Each chart must have a chart type, but we'll temporarily make this
    # null: true so that we can add types to existing charts first.
    add_reference :charts, :chart_type, foreign_key: true, null: true
  end
end
