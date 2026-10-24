# frozen_string_literal: true
module Permissible
  ADMIN = 1
  MOD = 2
  POWER_USER = 3
  SUSPENDED = 4
  READONLY = 5

  POWER_USER_PERMS = [
    :import_posts,
    :create_oauth_applications,
  ]

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
    :create_oauth_applications,
  ]

  def has_permission?(permission)
    return false unless role_id
    return true if admin?
    return true if power_user? && POWER_USER_PERMS.include?(permission)
    return false unless mod?
    MOD_PERMS.include?(permission)
  end

  def admin?
    role_id == ADMIN
  end

  def mod?
    role_id == MOD
  end

  def power_user?
    role_id == POWER_USER
  end

  def suspended?
    role_id == SUSPENDED
  end

  def read_only?
    role_id == READONLY
  end
end
