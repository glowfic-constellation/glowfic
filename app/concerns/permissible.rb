module Permissible
  ADMIN = 1
  MOD = 2

  MOD_PERMS = [
    # :edit_posts,
    # :edit_replies,
    # :edit_characters,
    # :edit_tags,
    # :delete_tags,
    # :edit_continuities
  ]

  def has_permission?(permission)
    return false unless role_id
    return true if admin?
    return false unless mod?
    MOD_PERMS.include?(permission)
  end

  def admin?
    role_id == ADMIN
  end

  def mod?
    role_id == MOD
  end
end
