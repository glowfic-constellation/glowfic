module Concealable
  PUBLIC = 0
  PRIVATE = 1
  ACCESS_LIST = 2
  REGISTERED = 3

  def public?
    privacy == PUBLIC
  end

  def registered_users?
    privacy == REGISTERED
  end

  def access_list?
    privacy == ACCESS_LIST
  end

  def private?
    privacy == PRIVATE
  end

  def visible_to?(user)
    # does not support access lists at this time
    return true if public?
    return false unless user
    return true if registered_users?
    return true if user.admin?
    user.id == user_id
  end
end
