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

ActiveRecord::Schema.define(version: 2014_05_11_061100) do

  create_table "cas", force: :cascade do |t|
    t.integer "user_id"
    t.string "ca_password", limit: 16, null: false
    t.string "hostname", null: false
    t.string "country", null: false
    t.string "dn_st", null: false
    t.string "dn_l", null: false
    t.string "dn_o", null: false
    t.string "dn_ou"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index "\":hostname,\", \":user_id\"", name: "index_cas_on_:hostname,_and_:user_id", unique: true
    t.index ["user_id"], name: "index_cas_on_user_id"
  end

  create_table "csrs", force: :cascade do |t|
    t.integer "user_id"
    t.string "hostname", null: false
    t.string "country", null: false
    t.string "dn_st", null: false
    t.string "dn_l", null: false
    t.string "dn_o", null: false
    t.string "dn_ou"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index "\":hostname,\", \":user_id\"", name: "index_csrs_on_:hostname,_and_:user_id", unique: true
    t.index ["user_id"], name: "index_csrs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cas", "users"
  add_foreign_key "csrs", "users"
end
