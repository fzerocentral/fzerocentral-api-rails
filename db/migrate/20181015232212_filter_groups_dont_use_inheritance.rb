class FilterGroupsDontUseInheritance < ActiveRecord::Migration[5.2]
  def change
    rename_column :filter_groups, :type, :kind
    # Instead of 'StandardFilterGroup' and 'NumericFilterGroup', let's just
    # have 'select' and 'numeric'
    change_column_default :filter_groups, :kind, 'select'
  end
end
