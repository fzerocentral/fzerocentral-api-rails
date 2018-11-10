class FilterBelongsToOneGroup < ActiveRecord::Migration[5.2]
  def change
    # Add belongs-to scheme.
    add_column :filters, :order_in_group, :integer
    # This will be null temporarily, so we can move existing filter group
    # memberships to the new belongs-to relationship.
    add_reference :filters, :filter_group, foreign_key: true, null: true
  end
end
