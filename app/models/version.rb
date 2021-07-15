class Version < PaperTrail::Version
  self.abstract_class = true

  belongs_to :user, optional: true

  alias_attribute :user_id, :whodunnit
end
