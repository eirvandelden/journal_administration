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

ActiveRecord::Schema[8.1].define(version: 2026_07_18_120001) do
  create_table "account_aliases", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "pattern", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(pattern)", name: "index_account_aliases_on_lower_pattern", unique: true
    t.index ["account_id", "pattern"], name: "index_account_aliases_on_account_id_and_pattern", unique: true
    t.index ["account_id"], name: "index_account_aliases_on_account_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "account_number"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "owner"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_accounts_on_category_id"
    t.index ["id"], name: "index_accounts_on_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appkit_push_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["endpoint"], name: "index_appkit_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_appkit_push_subscriptions_on_user_id"
  end

  create_table "budget_categories", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "budget_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "category_id"], name: "index_budget_categories_on_budget_id_and_category_id", unique: true
    t.index ["budget_id"], name: "index_budget_categories_on_budget_id"
    t.index ["category_id"], name: "index_budget_categories_on_category_id"
    t.check_constraint "amount > 0", name: "check_budget_category_amount_positive"
  end

  create_table "budgets", force: :cascade do |t|
    t.integer "closed_by_budget_id"
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closed_by_budget_id"], name: "index_budgets_on_closed_by_budget_id"
    t.index ["starts_at"], name: "index_budgets_on_starts_at", unique: true
    t.check_constraint "ends_at IS NULL OR starts_at < ends_at", name: "check_budget_dates"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "direction"
    t.string "name"
    t.integer "parent_category_id"
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_categories_on_id"
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
  end

  create_table "chattels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind"
    t.datetime "left_possession_at"
    t.string "model_number"
    t.string "name", null: false
    t.text "notes"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.integer "purchase_transaction_id"
    t.datetime "purchased_at"
    t.string "serial_number"
    t.datetime "updated_at", null: false
    t.datetime "warranty_expires_at"
    t.index ["purchase_transaction_id"], name: "index_chattels_on_purchase_transaction_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "ip_address"
    t.datetime "last_active_at", precision: nil, null: false
    t.string "token", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transaction_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "source_transaction_id", null: false
    t.integer "transfer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["source_transaction_id"], name: "index_transaction_links_on_source_transaction_id"
    t.index ["transfer_id"], name: "index_transaction_links_on_transfer_id", unique: true
  end

  create_table "transaction_splits", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.text "note"
    t.boolean "remainder", default: false, null: false
    t.integer "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_transaction_splits_on_category_id"
    t.index ["transaction_id"], name: "index_transaction_splits_on_transaction_id"
    t.check_constraint "amount > 0", name: "transaction_splits_amount_positive"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "booked_at", precision: nil
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.bigint "creditor_account_id"
    t.bigint "debitor_account_id"
    t.datetime "interest_at", precision: nil
    t.text "note"
    t.decimal "original_balance_after_mutation"
    t.text "original_note"
    t.string "original_tag"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["id"], name: "index_transactions_on_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "color_scheme", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "dark_theme", default: 1, null: false
    t.string "email_address", null: false
    t.integer "light_theme", default: 1, null: false
    t.integer "locale", default: 0, null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "account_aliases", "accounts"
  add_foreign_key "accounts", "categories"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "appkit_push_subscriptions", "users"
  add_foreign_key "budget_categories", "budgets"
  add_foreign_key "budget_categories", "categories"
  add_foreign_key "budgets", "budgets", column: "closed_by_budget_id", on_delete: :nullify
  add_foreign_key "chattels", "transactions", column: "purchase_transaction_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "transaction_links", "transactions", column: "source_transaction_id"
  add_foreign_key "transaction_links", "transactions", column: "transfer_id"
  add_foreign_key "transaction_splits", "categories"
  add_foreign_key "transaction_splits", "transactions"
  add_foreign_key "transactions", "categories"
end
