class FilterDeleteOrderInGroup < ActiveRecord::Migration[5.2]
  def change
    remove_index "filters", name: "index_filters_on_group_and_order"
    remove_column "filters", "order_in_group"
  end
end
