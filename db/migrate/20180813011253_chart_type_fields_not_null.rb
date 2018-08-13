class ChartTypeFieldsNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :charts, :chart_type_id, false
    change_column_null :chart_types, :name, false
    change_column_null :chart_types, :format_spec, false
    change_column_null :chart_types, :order_ascending, false
  end
end
