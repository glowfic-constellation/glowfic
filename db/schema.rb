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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160731040017) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "board_authors", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "board_id",                      :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "cameo",      :default => false
  end

  add_index "board_authors", ["board_id"], :name => "index_board_authors_on_board_id"
  add_index "board_authors", ["user_id"], :name => "index_board_authors_on_user_id"

  create_table "board_sections", :force => true do |t|
    t.integer  "board_id",                     :null => false
    t.string   "name",                         :null => false
    t.integer  "status",        :default => 0, :null => false
    t.integer  "section_order",                :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "board_views", :force => true do |t|
    t.integer  "board_id",                          :null => false
    t.integer  "user_id",                           :null => false
    t.boolean  "ignored",        :default => false
    t.boolean  "notify_message", :default => false
    t.boolean  "notify_email",   :default => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "board_views", ["user_id", "board_id"], :name => "index_board_views_on_user_id_and_board_id"

  create_table "boards", :force => true do |t|
    t.string   "name",        :null => false
    t.integer  "creator_id",  :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "description"
  end

  create_table "character_groups", :force => true do |t|
    t.integer "user_id", :null => false
    t.string  "name",    :null => false
  end

  create_table "character_tags", :force => true do |t|
    t.integer  "character_id", :null => false
    t.integer  "tag_id",       :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "character_tags", ["character_id"], :name => "index_character_tags_on_character_id"
  add_index "character_tags", ["tag_id"], :name => "index_character_tags_on_tag_id"

  create_table "characters", :force => true do |t|
    t.integer  "user_id",            :null => false
    t.string   "name",               :null => false
    t.string   "template_name"
    t.string   "screenname"
    t.integer  "template_id"
    t.integer  "default_icon_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "pb"
    t.integer  "character_group_id"
    t.string   "setting"
  end

  add_index "characters", ["character_group_id"], :name => "index_characters_on_character_group_id"
  add_index "characters", ["template_id"], :name => "index_characters_on_template_id"
  add_index "characters", ["user_id"], :name => "index_characters_on_user_id"

  create_table "characters_galleries", :force => true do |t|
    t.integer "character_id", :null => false
    t.integer "gallery_id",   :null => false
  end

  add_index "characters_galleries", ["character_id"], :name => "index_characters_galleries_on_character_id"
  add_index "characters_galleries", ["gallery_id"], :name => "index_characters_galleries_on_gallery_id"

  create_table "continuity_memberships", :force => true do |t|
    t.integer  "board_id",     :null => false
    t.integer  "character_id", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "continuity_memberships", ["board_id"], :name => "index_continuity_memberships_on_board_id"
  add_index "continuity_memberships", ["character_id"], :name => "index_continuity_memberships_on_character_id"

  create_table "galleries", :force => true do |t|
    t.integer  "user_id",       :null => false
    t.string   "name",          :null => false
    t.integer  "cover_icon_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "galleries", ["user_id"], :name => "index_galleries_on_user_id"

  create_table "galleries_icons", :force => true do |t|
    t.integer "icon_id"
    t.integer "gallery_id"
  end

  add_index "galleries_icons", ["gallery_id"], :name => "index_galleries_icons_on_gallery_id"
  add_index "galleries_icons", ["icon_id"], :name => "index_galleries_icons_on_icon_id"

  create_table "icons", :force => true do |t|
    t.integer  "user_id",                        :null => false
    t.string   "url",                            :null => false
    t.string   "keyword",                        :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "credit"
    t.boolean  "has_gallery", :default => false
  end

  add_index "icons", ["has_gallery"], :name => "index_icons_on_has_gallery"
  add_index "icons", ["keyword"], :name => "index_icons_on_keyword"
  add_index "icons", ["url"], :name => "index_icons_on_url"
  add_index "icons", ["user_id"], :name => "index_icons_on_user_id"

  create_table "messages", :force => true do |t|
    t.integer  "sender_id",                         :null => false
    t.integer  "recipient_id",                      :null => false
    t.integer  "parent_id"
    t.integer  "thread_id"
    t.string   "subject"
    t.text     "message"
    t.boolean  "unread",         :default => true
    t.boolean  "visible_inbox",  :default => true
    t.boolean  "visible_outbox", :default => true
    t.boolean  "marked_inbox",   :default => false
    t.boolean  "marked_outbox",  :default => false
    t.datetime "read_at"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "messages", ["recipient_id", "unread"], :name => "index_messages_on_recipient_id_and_unread"
  add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"

  create_table "password_resets", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "auth_token",                    :null => false
    t.boolean  "used",       :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "password_resets", ["auth_token"], :name => "index_password_resets_on_auth_token", :unique => true

  create_table "post_tags", :force => true do |t|
    t.integer  "post_id",                       :null => false
    t.integer  "user_id",                       :null => false
    t.integer  "tag_id",                        :null => false
    t.boolean  "suggested",  :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "post_tags", ["post_id"], :name => "index_post_tags_on_post_id"
  add_index "post_tags", ["tag_id"], :name => "index_post_tags_on_tag_id"

  create_table "post_viewers", :force => true do |t|
    t.integer  "post_id",    :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "post_viewers", ["post_id"], :name => "index_post_viewers_on_post_id"

  create_table "post_views", :force => true do |t|
    t.integer  "post_id",                           :null => false
    t.integer  "user_id",                           :null => false
    t.boolean  "ignored",        :default => false
    t.boolean  "notify_message", :default => false
    t.boolean  "notify_email",   :default => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "post_views", ["user_id", "post_id"], :name => "index_post_views_on_user_id_and_post_id"

  create_table "posts", :force => true do |t|
    t.integer  "board_id",                     :null => false
    t.integer  "user_id",                      :null => false
    t.string   "subject",                      :null => false
    t.text     "content"
    t.integer  "character_id"
    t.integer  "icon_id"
    t.integer  "privacy",       :default => 0, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "status"
    t.integer  "section_id"
    t.integer  "section_order"
    t.string   "description"
    t.integer  "last_user_id"
    t.integer  "last_reply_id"
    t.datetime "edited_at"
    t.datetime "tagged_at"
  end

  add_index "posts", ["board_id"], :name => "index_posts_on_board_id"
  add_index "posts", ["character_id"], :name => "index_posts_on_character_id"
  add_index "posts", ["icon_id"], :name => "index_posts_on_icon_id"
  add_index "posts", ["user_id"], :name => "index_posts_on_user_id"

  create_table "replies", :force => true do |t|
    t.integer  "post_id",      :null => false
    t.integer  "user_id",      :null => false
    t.text     "content"
    t.integer  "character_id"
    t.integer  "icon_id"
    t.integer  "thread_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "replies", ["character_id"], :name => "index_replies_on_character_id"
  add_index "replies", ["icon_id"], :name => "index_replies_on_icon_id"
  add_index "replies", ["post_id"], :name => "index_replies_on_post_id"
  add_index "replies", ["thread_id"], :name => "index_replies_on_thread_id"
  add_index "replies", ["user_id"], :name => "index_replies_on_user_id"

  create_table "reply_drafts", :force => true do |t|
    t.integer  "post_id",      :null => false
    t.integer  "user_id",      :null => false
    t.text     "content"
    t.integer  "character_id"
    t.integer  "icon_id"
    t.integer  "thread_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "reply_drafts", ["post_id", "user_id"], :name => "index_reply_drafts_on_post_id_and_user_id"

  create_table "tags", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "type"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"
  add_index "tags", ["type"], :name => "index_tags_on_type"

  create_table "templates", :force => true do |t|
    t.integer  "user_id",            :null => false
    t.string   "name"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "character_group_id"
  end

  add_index "templates", ["character_group_id"], :name => "index_templates_on_character_group_id"
  add_index "templates", ["user_id"], :name => "index_templates_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "username",                                               :null => false
    t.string   "crypted",                                                :null => false
    t.integer  "avatar_id"
    t.integer  "active_character_id"
    t.integer  "per_page",             :default => 25
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.string   "timezone"
    t.string   "email"
    t.boolean  "email_notifications"
    t.boolean  "icon_picker_grouping", :default => true
    t.string   "moiety"
    t.string   "layout"
    t.string   "moiety_name"
    t.string   "default_view"
    t.string   "default_editor",       :default => "rtf"
    t.string   "time_display",         :default => "%b %d, %Y %l:%M %p"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
