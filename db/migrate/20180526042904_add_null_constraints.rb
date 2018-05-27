# Didn't realize null:true was the default. Time to fix those constraints then.
# Also, leaf_chart_group's FK to chart_group should be mandatory.
class AddNullConstraints < ActiveRecord::Migration[5.1]
  def change
    change_column_null :games, :name, false
    change_column_null :chart_groups, :name, false
    change_column_null :chart_groups, :game_id, false
    change_column_null :leaf_chart_groups, :chart_group_id, false
    change_column_null :charts, :name, false
    change_column_null :charts, :leaf_chart_group_id, false
  end
end
