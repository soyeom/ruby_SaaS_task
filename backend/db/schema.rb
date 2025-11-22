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

ActiveRecord::Schema[8.1].define(version: 2025_11_22_173347) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id", "workspace_id"], name: "index_members_on_user_id_and_workspace_id", unique: true
    t.index ["user_id"], name: "index_members_on_user_id"
    t.index ["workspace_id"], name: "index_members_on_workspace_id"
  end

  create_table "task_progresses", force: :cascade do |t|
    t.datetime "aggregated_at", null: false
    t.integer "completed_tasks", default: 0, null: false
    t.integer "completion_rate", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "total_tasks", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id"], name: "index_task_progresses_on_user_id"
    t.index ["workspace_id", "user_id"], name: "index_task_progresses_on_workspace_id_and_user_id", unique: true
    t.index ["workspace_id"], name: "index_task_progresses_on_workspace_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assignee_id", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["workspace_id"], name: "index_tasks_on_workspace_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "login_id", null: false
    t.string "password", null: false
    t.datetime "updated_at", null: false
    t.index ["login_id"], name: "index_users_on_login_id", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "members", "users"
  add_foreign_key "members", "workspaces"
  add_foreign_key "task_progresses", "users"
  add_foreign_key "task_progresses", "workspaces"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "tasks", "workspaces"
end
