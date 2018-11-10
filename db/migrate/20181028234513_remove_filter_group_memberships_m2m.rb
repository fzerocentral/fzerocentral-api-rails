class RemoveFilterGroupMembershipsM2m < ActiveRecord::Migration[5.2]
  def change
    # Remove m2m scheme.
    # An empty options block {} ensures this operation can be reverted.
    drop_table :filter_group_memberships, {}

    # Make sure that existing filter group memberships have been moved to the
    # new belongs-to relationship. We'll now enforce non-null on that relation.
    change_column_null :filters, :filter_group_id, false
    # And guess we forgot to add a unique index.
    add_index :filters, [:filter_group_id, :order_in_group], unique: true, name: 'index_filters_on_group_and_order'
  end
end
