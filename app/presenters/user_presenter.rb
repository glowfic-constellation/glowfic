class UserPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def as_json(options={})
    return {} unless user
    return {id: user.id, username: '(deleted user)'} if user.deleted?
    user.as_json_without_presenter({only: [:id, :username]}.reverse_merge(options))
  end
end
