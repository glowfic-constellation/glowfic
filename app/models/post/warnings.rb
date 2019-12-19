module Post::Warnings
  extend ActiveSupport::Concern
  included do
    def hide_warnings_for(user)
      view_for(user).update(warnings_hidden: true)
    end

    def show_warnings_for?(user)
      return false if user.hide_warnings
      !view_for(user).try(:warnings_hidden)
    end

    def has_content_warnings?
      return read_attribute(:has_content_warnings) if has_attribute?(:has_content_warnings)
      content_warnings.exists?
    end

    private

    def reset_warnings(_warning)
      Post::View.where(post_id: id).update_all(warnings_hidden: false)
    end
  end
end
