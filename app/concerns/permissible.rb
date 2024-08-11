# frozen_string_literal: true
module Permissible
  ADMIN = 1
  MOD = 2
  IMPORTER = 3
  SUSPENDED = 4
  READONLY = 5

  MOD_PERMS = [
    :edit_posts,
    :edit_replies,
    :edit_characters,
    :import_posts,
    :split_posts,
    :regenerate_flat_posts,
    :relocate_characters,
    # :edit_tags,
    # :delete_tags,
    # :edit_continuities
    :create_news,
  ]

  def has_permission?(permission)
    return false unless role_id
    return true if admin?
    return true if importer? && permission == :import_posts
    return false unless mod?
    MOD_PERMS.include?(permission)
  end

  def admin?
    role_id == ADMIN
  end

  def mod?
    role_id == MOD
  end

  def importer?
    role_id == IMPORTER
  end

  def suspended?
    role_id == SUSPENDED
  end

  def read_only?
    role_id == READONLY
  end
end
