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

ActiveRecord::Schema.define(version: 20141008085158) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "canned_statements", force: true do |t|
    t.text    "body"
    t.integer "user_id"
  end

  create_table "conversations", force: true do |t|
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.string   "initial"
    t.string   "reply"
    t.string   "finished"
    t.boolean  "initial_viewed"
    t.boolean  "reply_viewed"
    t.boolean  "finished_viewed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
  end

  create_table "mutes", force: true do |t|
    t.integer  "receiver_id"
    t.integer  "sender_id"
    t.integer  "conversation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
  end

  create_table "pending_conversations", force: true do |t|
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.integer  "conversation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: true do |t|
    t.string   "auth_token"
    t.string   "device"
    t.string   "device_token"
    t.integer  "user_id"
    t.datetime "updated_at"
    t.string   "api_key"
    t.datetime "created_at"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.date     "date_of_birth"
    t.string   "user_name"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "facebook_uid"
    t.string   "facebook_avatar"
    t.integer  "sent_rating",            default: 0
    t.integer  "received_rating",        default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["latitude"], name: "index_users_on_latitude", using: :btree
  add_index "users", ["longitude"], name: "index_users_on_longitude", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
