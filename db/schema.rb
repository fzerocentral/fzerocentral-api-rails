# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_20_190731) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chart_groups", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "game_id", null: false
    t.bigint "parent_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_in_parent", null: false
    t.boolean "show_charts_together"
    t.index ["game_id"], name: "index_chart_groups_on_game_id"
    t.index ["parent_group_id", "order_in_parent"], name: "index_chart_groups_on_parent_group_id_and_order_in_parent", unique: true
    t.index ["parent_group_id"], name: "index_chart_groups_on_parent_group_id"
  end

  create_table "chart_type_filter_groups", force: :cascade do |t|
    t.bigint "chart_type_id", null: false
    t.bigint "filter_group_id", null: false
    t.boolean "show_by_default", default: true, null: false
    t.integer "order_in_chart_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chart_type_id", "filter_group_id"], name: "index_chart_type_filter_groups_on_ct_and_fg", unique: true
    t.index ["chart_type_id", "order_in_chart_type"], name: "index_chart_type_filter_groups_on_ct_and_order", unique: true
    t.index ["chart_type_id"], name: "index_chart_type_filter_groups_on_chart_type_id"
    t.index ["filter_group_id"], name: "index_chart_type_filter_groups_on_filter_group_id"
  end

  create_table "chart_types", force: :cascade do |t|
    t.string "name", null: false
    t.json "format_spec", null: false
    t.boolean "order_ascending", null: false
    t.bigint "game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_chart_types_on_game_id"
  end

  create_table "charts", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chart_group_id", null: false
    t.integer "order_in_group", null: false
    t.bigint "chart_type_id", null: false
    t.index ["chart_group_id", "order_in_group"], name: "index_charts_on_chart_group_id_and_order_in_group", unique: true
    t.index ["chart_group_id"], name: "index_charts_on_chart_group_id"
    t.index ["chart_type_id"], name: "index_charts_on_chart_type_id"
  end

  create_table "filter_groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.string "kind", default: "select", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "filter_implication_links", force: :cascade do |t|
    t.bigint "implying_filter_id", null: false
    t.bigint "implied_filter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["implied_filter_id"], name: "index_filter_implication_links_on_implied_filter_id"
    t.index ["implying_filter_id", "implied_filter_id"], name: "index_filter_implication_links_on_implying_and_implied", unique: true
    t.index ["implying_filter_id"], name: "index_filter_implication_links_on_implying_filter_id"
  end

  create_table "filter_implications", force: :cascade do |t|
    t.bigint "implying_filter_id", null: false
    t.bigint "implied_filter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["implied_filter_id"], name: "index_filter_implications_on_implied_filter_id"
    t.index ["implying_filter_id", "implied_filter_id"], name: "index_filter_implications_on_implying_and_implied", unique: true
    t.index ["implying_filter_id"], name: "index_filter_implications_on_implying_filter_id"
  end

  create_table "filters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "numeric_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "filter_group_id", null: false
    t.string "usage_type", default: "choosable", null: false
    t.index ["filter_group_id"], name: "index_filters_on_filter_group_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ladders", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.string "filter_spec", null: false
    t.bigint "chart_group_id", null: false
    t.bigint "game_id", null: false
    t.integer "order_in_game_and_kind", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["chart_group_id"], name: "index_ladders_on_chart_group_id"
    t.index ["game_id", "kind", "order_in_game_and_kind"], name: "index_ladders_on_game_id_and_kind_and_order_in_game_and_kind", unique: true
    t.index ["game_id"], name: "index_ladders_on_game_id"
  end

  create_table "record_filters", force: :cascade do |t|
    t.bigint "record_id", null: false
    t.bigint "filter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filter_id"], name: "index_record_filters_on_filter_id"
    t.index ["record_id", "filter_id"], name: "index_record_filters_on_record_id_and_filter_id", unique: true
    t.index ["record_id"], name: "index_record_filters_on_record_id"
  end

  create_table "records", force: :cascade do |t|
    t.bigint "value", null: false
    t.datetime "achieved_at"
    t.bigint "chart_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chart_id"], name: "index_records_on_chart_id"
    t.index ["user_id"], name: "index_records_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "chart_groups", "chart_groups", column: "parent_group_id"
  add_foreign_key "chart_groups", "games"
  add_foreign_key "chart_type_filter_groups", "chart_types"
  add_foreign_key "chart_type_filter_groups", "filter_groups"
  add_foreign_key "chart_types", "games"
  add_foreign_key "charts", "chart_groups"
  add_foreign_key "charts", "chart_types"
  add_foreign_key "filter_implication_links", "filters", column: "implied_filter_id"
  add_foreign_key "filter_implication_links", "filters", column: "implying_filter_id"
  add_foreign_key "filter_implications", "filters", column: "implied_filter_id"
  add_foreign_key "filter_implications", "filters", column: "implying_filter_id"
  add_foreign_key "filters", "filter_groups"
  add_foreign_key "ladders", "chart_groups"
  add_foreign_key "ladders", "games"
  add_foreign_key "record_filters", "filters"
  add_foreign_key "record_filters", "records"
  add_foreign_key "records", "charts"
  add_foreign_key "records", "users"
end
