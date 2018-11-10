class CreateFilters < ActiveRecord::Migration[5.2]
  def change
    create_table :filters do |t|
      t.string :name, null: false
      t.integer :numeric_value

      t.timestamps
    end

    # many-to-many
    create_table :filter_group_memberships do |t|
      t.references :filter_group, foreign_key: true, null: false
      t.references :filter, foreign_key: true, null: false
      t.integer :order_in_group, null: false

      t.timestamps
    end

    # These indexes' names become too long if auto-generated, so we have to
    # define names ourselves.
    add_index :filter_group_memberships, [:filter_group_id, :filter_id], unique: true, name: 'index_filter_group_memberships_on_fg_and_filter'
    add_index :filter_group_memberships, [:filter_group_id, :order_in_group], unique: true, name: 'index_filter_group_memberships_on_fg_and_order'

    # many-to-many self-join
    create_table :filter_implications do |t|
      t.references :filter, foreign_key: true, null: false
      # Since this field's name is different from the table it references,
      # we have to define the foreign key constraint after table creation.
      t.references :implied_filter, null: false

      t.timestamps
    end

    add_foreign_key :filter_implications, :filters, column: :implied_filter_id
    add_index :filter_implications, [:filter_id, :implied_filter_id], unique: true, name: 'index_filter_implications_on_filter_and_if'

    # many-to-many
    create_table :record_filters do |t|
      t.references :record, foreign_key: true, null: false
      t.references :filter, foreign_key: true, null: false

      t.timestamps
    end

    add_index :record_filters, [:record_id, :filter_id], unique: true
  end
end
