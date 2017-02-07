class UserPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def as_json(options={})
    return {} unless user
    user.as_json_without_presenter({only: [:id, :username]}.reverse_merge(options))
  end
end
