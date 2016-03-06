module Viewable
  extend ActiveSupport::Concern

  included do
    has_many :views, class_name: self.name + 'View'

    def mark_read(user, at_time=nil)
      view = view_for(user)
      return true if view.ignored
      if at_time.present? && !view.new_record?
        return true if at_time <= view.updated_at
        return view.update_attributes(updated_at: at_time)
      end
      return view.save if view.new_record?
      view.touch
    end

    def ignore(user)
      view_for(user).update_attributes(ignored: true)
    end

    def ignored_by?(user)
      view_for(user).ignored
    end

    def last_read(user)
      view_for(user).updated_at
    end

    private

    def view_for(user)
      @view ||= views.where(user_id: user.id).first_or_initialize
    end
  end
end
