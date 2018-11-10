class FilterImplicationsRenameFilterField < ActiveRecord::Migration[5.2]
  def change
    rename_column :filter_implications, :filter_id, :implying_filter_id

    # The index for just the above column should've been renamed accordingly,
    # but the two-column index hasn't been renamed yet.
    rename_index :filter_implications, 'index_filter_implications_on_filter_and_if', 'index_filter_implications_on_implying_and_implied'
  end
end
