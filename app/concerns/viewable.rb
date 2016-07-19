module Viewable
  extend ActiveSupport::Concern

  included do
    has_many :views, class_name: self.name + 'View', dependent: :destroy

    def mark_read(user, at_time=nil)
      view = view_for(user)
      return true if view.ignored
      if view.new_record?
        view.updated_at = at_time
        view.save
      else
        return view.touch unless at_time.present?
        return true if at_time <= view.updated_at
        view.update_attributes(updated_at: at_time)
      end
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
