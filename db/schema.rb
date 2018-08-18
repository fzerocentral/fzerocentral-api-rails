# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_13_094520) do

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

  create_table "games", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  add_foreign_key "chart_types", "games"
  add_foreign_key "charts", "chart_groups"
  add_foreign_key "charts", "chart_types"
  add_foreign_key "records", "charts"
  add_foreign_key "records", "users"
end
