class ChartAndChartGroupConstrainOrder < ActiveRecord::Migration[5.1]
  def change
    change_column_null :chart_groups, :order_in_parent, false
    add_index :chart_groups, [:parent_group_id, :order_in_parent], unique: true

    change_column_null :charts, :order_in_group, false
    add_index :charts, [:chart_group_id, :order_in_group], unique: true
  end
end
