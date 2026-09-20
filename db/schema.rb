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

ActiveRecord::Schema[8.1].define(version: 2026_07_04_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", id: :serial, force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at", precision: nil
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
  end

  create_table "blocks", force: :cascade do |t|
    t.boolean "block_interactions", default: true
    t.integer "blocked_user_id", null: false
    t.integer "blocking_user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "hide_me", default: 0
    t.integer "hide_them", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.index ["blocked_user_id"], name: "index_blocks_on_blocked_user_id"
    t.index ["blocking_user_id"], name: "index_blocks_on_blocking_user_id"
  end

  create_table "board_authors", id: :serial, force: :cascade do |t|
    t.integer "board_id", null: false
    t.boolean "cameo", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["board_id"], name: "index_board_authors_on_board_id"
    t.index ["user_id"], name: "index_board_authors_on_user_id"
  end

  create_table "board_sections", id: :serial, force: :cascade do |t|
    t.integer "board_id", null: false
    t.datetime "created_at", precision: nil
    t.text "description"
    t.string "name", null: false
    t.integer "section_order", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", precision: nil
  end

  create_table "board_views", id: :serial, force: :cascade do |t|
    t.integer "board_id", null: false
    t.datetime "created_at", precision: nil
    t.boolean "ignored", default: false
    t.boolean "notify_email", default: false
    t.boolean "notify_message", default: false
    t.datetime "read_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["user_id", "board_id"], name: "index_board_views_on_user_id_and_board_id", unique: true
  end

  create_table "boards", id: :serial, force: :cascade do |t|
    t.boolean "authors_locked", default: true
    t.datetime "created_at", precision: nil
    t.integer "creator_id", null: false
    t.text "description"
    t.boolean "mega", default: false
    t.citext "name", null: false
    t.boolean "pinned", default: false
    t.datetime "updated_at", precision: nil
  end

  create_table "bookmarks", force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.integer "post_id", null: false
    t.boolean "public", default: false, null: false
    t.integer "reply_id", null: false
    t.string "type", default: "reply_bookmark", null: false
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["post_id", "user_id"], name: "index_bookmarks_on_post_id_and_user_id"
    t.index ["post_id"], name: "index_bookmarks_on_post_id"
    t.index ["reply_id"], name: "index_bookmarks_on_reply_id"
    t.index ["user_id", "reply_id", "type"], name: "index_bookmarks_on_user_id_and_reply_id_and_type", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "character_aliases", id: :serial, force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", precision: nil
    t.string "name", null: false
    t.datetime "updated_at", precision: nil
    t.index ["character_id"], name: "index_character_aliases_on_character_id"
  end

  create_table "character_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
  end

  create_table "character_tags", id: :serial, force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", precision: nil
    t.integer "tag_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["character_id"], name: "index_character_tags_on_character_id"
    t.index ["tag_id"], name: "index_character_tags_on_tag_id"
  end

  create_table "characters", id: :serial, force: :cascade do |t|
    t.integer "character_group_id"
    t.string "cluster"
    t.datetime "created_at", precision: nil
    t.integer "default_icon_id"
    t.text "description"
    t.citext "name", null: false
    t.string "nickname"
    t.boolean "npc", default: false, null: false
    t.string "pb"
    t.boolean "retired", default: false
    t.string "screenname"
    t.integer "template_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["character_group_id"], name: "index_characters_on_character_group_id"
    t.index ["template_id"], name: "index_characters_on_template_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "characters_galleries", id: :serial, force: :cascade do |t|
    t.boolean "added_by_group", default: false
    t.integer "character_id", null: false
    t.integer "gallery_id", null: false
    t.integer "section_order", default: 0, null: false
    t.index ["character_id"], name: "index_characters_galleries_on_character_id"
    t.index ["gallery_id"], name: "index_characters_galleries_on_gallery_id"
  end

  create_table "favorites", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "favorite_id", null: false
    t.string "favorite_type", null: false
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["favorite_id", "favorite_type"], name: "index_favorites_on_favorite_id_and_favorite_type"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "flat_posts", id: :serial, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil
    t.integer "post_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["post_id"], name: "index_flat_posts_on_post_id"
  end

  create_table "galleries", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "name", null: false
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_galleries_on_user_id"
  end

  create_table "galleries_icons", id: :serial, force: :cascade do |t|
    t.integer "gallery_id"
    t.integer "icon_id"
    t.index ["gallery_id"], name: "index_galleries_icons_on_gallery_id"
    t.index ["icon_id"], name: "index_galleries_icons_on_icon_id"
  end

  create_table "gallery_tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "gallery_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["gallery_id"], name: "index_gallery_tags_on_gallery_id"
    t.index ["tag_id"], name: "index_gallery_tags_on_tag_id"
  end

  create_table "icons", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "credit"
    t.boolean "has_gallery", default: false
    t.string "keyword", null: false
    t.string "s3_key"
    t.datetime "updated_at", precision: nil
    t.string "url", null: false
    t.integer "user_id", null: false
    t.index ["has_gallery"], name: "index_icons_on_has_gallery"
    t.index ["keyword"], name: "index_icons_on_keyword"
    t.index ["url"], name: "index_icons_on_url"
    t.index ["user_id"], name: "index_icons_on_user_id"
  end

  create_table "index_posts", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "index_id", null: false
    t.integer "index_section_id"
    t.integer "post_id", null: false
    t.integer "section_order"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["index_id"], name: "index_index_posts_on_index_id"
    t.index ["post_id"], name: "index_index_posts_on_post_id"
  end

  create_table "index_sections", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "index_id", null: false
    t.citext "name", null: false
    t.integer "section_order"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["index_id"], name: "index_index_sections_on_index_id"
  end

  create_table "indexes", id: :serial, force: :cascade do |t|
    t.boolean "authors_locked", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.citext "name", null: false
    t.integer "privacy", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_indexes_on_user_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.boolean "marked_inbox", default: false
    t.boolean "marked_outbox", default: false
    t.text "message"
    t.integer "notification_id"
    t.integer "parent_id"
    t.datetime "read_at", precision: nil
    t.integer "recipient_id", null: false
    t.integer "sender_id", null: false
    t.string "subject"
    t.integer "thread_id"
    t.boolean "unread", default: true
    t.datetime "updated_at", precision: nil
    t.boolean "visible_inbox", default: true
    t.boolean "visible_outbox", default: true
    t.index ["recipient_id", "unread"], name: "index_messages_on_recipient_id_and_unread"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["thread_id"], name: "index_messages_on_thread_id"
  end

  create_table "news", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
  end

  create_table "news_views", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "news_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_news_views_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "error_msg"
    t.integer "notification_type", null: false
    t.integer "post_id"
    t.datetime "read_at", precision: nil
    t.boolean "unread", default: true, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "password_resets", id: :serial, force: :cascade do |t|
    t.string "auth_token", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "used", default: false
    t.integer "user_id", null: false
    t.index ["auth_token"], name: "index_password_resets_on_auth_token", unique: true
    t.index ["user_id", "created_at"], name: "index_password_resets_on_user_id_and_created_at"
  end

  create_table "post_authors", id: :serial, force: :cascade do |t|
    t.boolean "can_owe", default: true
    t.boolean "can_reply", default: true
    t.datetime "created_at", precision: nil
    t.boolean "joined", default: false
    t.datetime "joined_at", precision: nil
    t.integer "post_id", null: false
    t.text "private_note"
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_post_authors_on_post_id"
    t.index ["user_id"], name: "index_post_authors_on_user_id"
  end

  create_table "post_tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "post_id", null: false
    t.boolean "suggested", default: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "post_viewers", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "post_id", null: false
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_post_viewers_on_post_id"
  end

  create_table "post_views", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.boolean "ignored", default: false
    t.boolean "notify_email", default: false
    t.boolean "notify_message", default: false
    t.integer "post_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.boolean "warnings_hidden", default: false
    t.index ["user_id", "post_id"], name: "index_post_views_on_user_id_and_post_id", unique: true
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.boolean "authors_locked", default: false
    t.integer "board_id", null: false
    t.integer "character_alias_id"
    t.integer "character_id"
    t.text "content"
    t.datetime "created_at", precision: nil
    t.string "description"
    t.datetime "edited_at", precision: nil
    t.string "editor_mode"
    t.integer "icon_id"
    t.integer "last_reply_id"
    t.integer "last_user_id"
    t.integer "privacy", default: 0, null: false
    t.integer "section_id"
    t.integer "section_order"
    t.integer "status", default: 0
    t.string "subject", null: false
    t.datetime "tagged_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index "to_tsvector('english'::regconfig, COALESCE((subject)::text, ''::text))", name: "idx_fts_post_subject", using: :gin
    t.index "to_tsvector('english'::regconfig, COALESCE(content, ''::text))", name: "idx_fts_post_content", using: :gin
    t.index ["board_id"], name: "index_posts_on_board_id"
    t.index ["character_id"], name: "index_posts_on_character_id"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["icon_id"], name: "index_posts_on_icon_id"
    t.index ["tagged_at"], name: "index_posts_on_tagged_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "replies", id: :serial, force: :cascade do |t|
    t.integer "character_alias_id"
    t.integer "character_id"
    t.text "content"
    t.datetime "created_at", precision: nil
    t.string "editor_mode"
    t.integer "icon_id"
    t.integer "post_id", null: false
    t.integer "reply_order"
    t.integer "thread_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.integer "word_count"
    t.index "to_tsvector('english'::regconfig, COALESCE(content, ''::text))", name: "idx_fts_reply_content", using: :gin
    t.index ["character_id"], name: "index_replies_on_character_id"
    t.index ["created_at"], name: "index_replies_on_created_at"
    t.index ["icon_id"], name: "index_replies_on_icon_id"
    t.index ["post_id", "reply_order"], name: "index_replies_on_post_id_and_reply_order"
    t.index ["post_id"], name: "index_replies_on_post_id"
    t.index ["thread_id"], name: "index_replies_on_thread_id"
    t.index ["user_id"], name: "index_replies_on_user_id"
  end

  create_table "reply_drafts", id: :serial, force: :cascade do |t|
    t.integer "character_alias_id"
    t.integer "character_id"
    t.text "content"
    t.datetime "created_at", precision: nil
    t.string "editor_mode"
    t.integer "icon_id"
    t.integer "post_id", null: false
    t.integer "thread_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["post_id", "user_id"], name: "index_reply_drafts_on_post_id_and_user_id"
  end

  create_table "report_views", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "read_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_report_views_on_user_id"
  end

  create_table "tag_tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.boolean "suggested", default: false
    t.integer "tag_id", null: false
    t.integer "tagged_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["tag_id"], name: "index_tag_tags_on_tag_id"
    t.index ["tagged_id"], name: "index_tag_tags_on_tagged_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.text "description"
    t.citext "name", null: false
    t.boolean "owned", default: false
    t.string "type"
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["name"], name: "index_tags_on_name"
    t.index ["type"], name: "index_tags_on_type"
  end

  create_table "templates", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.text "description"
    t.citext "name"
    t.boolean "retired", default: false
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_templates_on_user_id"
  end

  create_table "user_tags", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "tag_id", null: false
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["tag_id"], name: "index_user_tags_on_tag_id"
    t.index ["user_id"], name: "index_user_tags_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "active_character_id"
    t.integer "avatar_id"
    t.datetime "created_at", precision: nil
    t.string "crypted", null: false
    t.string "default_character_split", default: "template"
    t.string "default_editor", default: "rtf"
    t.boolean "default_hide_add_bookmark_button", default: false
    t.boolean "default_hide_edit_delete_buttons", default: false
    t.boolean "default_hide_retired_characters", default: false
    t.string "default_view"
    t.boolean "deleted", default: false
    t.citext "email"
    t.boolean "email_notifications"
    t.boolean "favorite_notifications", default: true
    t.boolean "hide_from_all", default: false
    t.boolean "hide_hiatused_tags_owed", default: false
    t.boolean "hide_warnings", default: false
    t.boolean "icon_picker_grouping", default: true
    t.boolean "ignore_unread_daily_report", default: false
    t.string "layout"
    t.string "moiety"
    t.boolean "moiety_colors_unread", default: false
    t.string "moiety_name"
    t.integer "per_page", default: 25
    t.string "profile"
    t.string "profile_editor_mode", default: "html"
    t.boolean "public_bookmarks", default: false
    t.boolean "default_hide_edit_delete_buttons", default: false
    t.boolean "default_hide_add_bookmark_button", default: false
    t.string "rss_token"
    t.integer "role_id"
    t.string "salt_uuid"
    t.boolean "show_user_in_switcher", default: true
    t.string "time_display", default: "%b %d, %Y %l:%M %p"
    t.string "timezone"
    t.integer "tos_version"
    t.boolean "unread_opened", default: false
    t.datetime "updated_at", precision: nil
    t.citext "username", null: false
    t.boolean "visible_unread", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["rss_token"], name: "index_users_on_rss_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end
end
