# frozen_string_literal: true
module Permissible
  extend ActiveSupport::Concern

  PERMS = [
    :edit_posts,
    :edit_replies,
    :edit_characters,
    :import_posts,
    :create_news,
    :split_posts,
    :regenerate_flat_posts,
    :relocate_characters,
    # admin-only permissions start here
    :delete_replies,
    :edit_tags,
    :delete_tags,
    :edit_continuities,
    :edit_indexes,
    :edit_news,
    :delete_news,
  ]

  MOD_PERMS = PERMS[0..7]

  included do
    enum role_id: {
      admin: 1,
      mod: 2,
      importer: 3,
      suspended: 4,
      read_only: 5,
    }

    def has_permission?(permission)
      return false unless role_id
      return false unless PERMS.include?(permission)
      return true if admin?
      return true if importer? && permission == :import_posts
      return false unless mod?
      MOD_PERMS.include?(permission)
    end
  end
end
