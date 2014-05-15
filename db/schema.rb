# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140511061100) do

  create_table "cas", force: true do |t|
    t.integer  "user_id"
    t.string   "ca_password", limit: 16, null: false
    t.string   "hostname",               null: false
    t.string   "country",                null: false
    t.string   "dn_st",                  null: false
    t.string   "dn_l",                   null: false
    t.string   "dn_o",                   null: false
    t.string   "dn_ou"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cas", ["hostname", "user_id"], name: "index_cas_on_hostname_and_user_id", unique: true

  create_table "csrs", force: true do |t|
    t.integer  "user_id"
    t.string   "hostname",   null: false
    t.string   "country",    null: false
    t.string   "dn_st",      null: false
    t.string   "dn_l",       null: false
    t.string   "dn_o",       null: false
    t.string   "dn_ou"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "csrs", ["hostname", "user_id"], name: "index_csrs_on_hostname_and_user_id", unique: true

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
