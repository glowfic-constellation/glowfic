class Version < PaperTrail::Version
  self.abstract_class = true

  belongs_to :user, foreign_key: :whodunnit, optional: true, inverse_of: false

  alias_attribute :user_id, :whodunnit
  alias_attribute :action, :event

  def self.as_user(user)
    user_id = user.is_a?(User) ? user.id : user
    ::PaperTrail.request(whodunnit: user_id) { yield }
  end
end
