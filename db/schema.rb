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

ActiveRecord::Schema.define(version: 2023_11_09_194602) do

  create_table "accounts", force: :cascade do |t|
    t.string "account_number", limit: 255
    t.string "name", limit: 255
    t.integer "owner"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_accounts_on_category_id"
    t.index ["id"], name: "index_accounts_on_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "direction"
    t.integer "parent_category_id"
    t.index ["id"], name: "index_categories_on_id"
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
  end

  create_table "data_migrations", primary_key: "version", id: { type: :string, limit: 255 }, force: :cascade do |t|
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "debitor_account_id"
    t.bigint "creditor_account_id"
    t.decimal "amount"
    t.datetime "booked_at"
    t.datetime "interest_at"
    t.bigint "category_id"
    t.text "note"
    t.string "type", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "original_note"
    t.decimal "original_balance_after_mutation"
    t.string "original_tag"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["id"], name: "index_transactions_on_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", limit: 255, null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128, null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

  add_foreign_key "accounts", "categories"
  add_foreign_key "transactions", "categories"
end
