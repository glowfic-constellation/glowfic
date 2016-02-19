module Viewable
  extend ActiveSupport::Concern

  included do
    has_many :views, class_name: self.name + 'View'

    def mark_read(user)
      view = view_for(user)
      return true if view.ignored
      view.id.nil? ? view.save : view.touch
    end

    def ignore(user)
      view_for(user).update_attributes(ignored: true)
    end

    def ignored_by?(user)
      view_for(user).ignored
    end

    private

    def view_for(user)
      views.where(user_id: user.id).first_or_initialize
    end
  end
end
