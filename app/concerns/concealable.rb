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
end
