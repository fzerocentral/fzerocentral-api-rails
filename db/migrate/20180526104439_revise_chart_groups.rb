class ReviseChartGroups < ActiveRecord::Migration[5.1]
  def change
    # Charts belong to chart groups now, not leaf chart groups.
    # Here we're just being lazy and assuming no existing CGs or LCGs
    # need to be preserved.
    remove_reference :charts, :leaf_chart_group
    add_reference :charts, :chart_group, foreign_key: true, null: false
    # Leaf chart groups don't do anything now.
    # An empty options block {} ensures this operation can be reverted.
    drop_table :leaf_chart_groups, {}

    # Rename the recursive chart-group-to-chart-group FK.
    rename_column :chart_groups, :chart_group_id, :parent_group_id
  end
end
