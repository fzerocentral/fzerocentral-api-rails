class CreateFilterImplicationLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :filter_implication_links do |t|
      t.bigint "implying_filter_id", null: false
      t.bigint "implied_filter_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["implied_filter_id"], name: "index_filter_implication_links_on_implied_filter_id"
      t.index ["implying_filter_id", "implied_filter_id"], name: "index_filter_implication_links_on_implying_and_implied", unique: true
      t.index ["implying_filter_id"], name: "index_filter_implication_links_on_implying_filter_id"
    end

    add_foreign_key "filter_implication_links", "filters", column: "implied_filter_id"
    add_foreign_key "filter_implication_links", "filters", column: "implying_filter_id"
  end
end
