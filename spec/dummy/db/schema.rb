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

ActiveRecord::Schema.define(version: 20131018214212) do

  create_table "groups", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_users", id: false, force: true do |t|
    t.integer "group_id", null: false
    t.integer "user_id",  null: false
  end

  create_table "repo_items", force: true do |t|
    t.integer "owner_id"
    t.string  "owner_type"
    t.string  "ancestry"
    t.string  "name"
    t.float   "file_size"
    t.string  "content_type"
    t.string  "file"
    t.string  "type"
  end

  create_table "sharings", force: true do |t|
    t.integer "owner_id"
    t.string  "owner_type"
    t.integer "repo_item_id"
    t.boolean "can_create",   default: false
    t.boolean "can_read",     default: false
    t.boolean "can_update",   default: false
    t.boolean "can_delete",   default: false
    t.boolean "can_share",    default: false
  end

  create_table "sharings_members", force: true do |t|
    t.integer "sharing_id"
    t.integer "member_id"
    t.string  "member_type"
    t.boolean "can_add",     default: false
    t.boolean "can_remove",  default: false
  end

  create_table "users", force: true do |t|
    t.string   "nickname"
    t.string   "password"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
