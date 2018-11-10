class CreateFilterGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :filter_groups do |t|
      t.string :name, null: false
      t.string :description, null: false
      # Single-table inheritance
      t.string :type, null: false, default: 'StandardFilterGroup'

      t.timestamps
    end

    # many-to-many
    create_table :chart_type_filter_groups do |t|
      t.references :chart_type, foreign_key: true, null: false
      t.references :filter_group, foreign_key: true, null: false
      t.boolean :show_by_default, null: false, default: true
      t.integer :order_in_chart_type, null: false

      t.timestamps
    end

    # These indexes' names become too long if auto-generated, so we have to
    # define names ourselves.
    add_index :chart_type_filter_groups, [:chart_type_id, :filter_group_id], unique: true, name: 'index_chart_type_filter_groups_on_ct_and_fg'
    add_index :chart_type_filter_groups, [:chart_type_id, :order_in_chart_type], unique: true, name: 'index_chart_type_filter_groups_on_ct_and_order'
  end
end
