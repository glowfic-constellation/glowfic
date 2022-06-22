module Concealable
  extend ActiveSupport::Concern

  included do
    enum privacy: {
      public: 0,
      private: 1,
      access_list: 2,
      full_accounts: 3,
      registered: 4,
    }, _prefix: true

    def visible_to?(user)
      # does not support access lists at this time
      return true if privacy_public?
      return false unless user
      return true if privacy_registered?
      return false if user.read_only?
      return true if privacy_full_accounts?
      return true if user.admin?
      user.id == user_id
    end
  end
end
