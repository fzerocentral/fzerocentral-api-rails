class ChartAndChartGroupAddOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :chart_groups, :order_in_parent, :integer
    add_column :charts, :order_in_group, :integer
  end
end
