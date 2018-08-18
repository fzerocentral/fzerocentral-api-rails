class ChartGroupAddShowChartsTogetherFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :chart_groups, :show_charts_together, :boolean
  end
end
