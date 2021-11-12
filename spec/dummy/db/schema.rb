# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_01_031240) do

  create_table "todo_item_events", force: :cascade do |t|
    t.string "type", null: false
    t.integer "todo_item_id", null: false
    t.text "data", null: false
    t.text "metadata", null: false
    t.datetime "created_at", null: false
    t.index ["todo_item_id"], name: "index_todo_item_events_on_todo_item_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.integer "todo_list_id", null: false
    t.string "name", null: false
    t.datetime "due_date"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "todo_list_events", force: :cascade do |t|
    t.string "type", null: false
    t.integer "todo_list_id", null: false
    t.text "data", null: false
    t.text "metadata", null: false
    t.datetime "created_at", null: false
    t.index ["todo_list_id"], name: "index_todo_list_events_on_todo_list_id"
  end

  create_table "todo_lists", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
