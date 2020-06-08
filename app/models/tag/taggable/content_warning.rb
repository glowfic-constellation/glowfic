module Tag::Taggable::ContentWarning
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    attr_reader :content_warning_list, :content_warning_list_was, :content_warning_list_changed
    alias_method :content_warning_list_changed?, :content_warning_list_changed

    after_initialize :load_content_warning_tags
    after_save :save_content_warning_tags

    def content_warning_list=(list)
      list = Tag::List.new(list)
      return if list == content_warning_list
      @content_warning_list_changed = true
      @content_warning_list_was = @content_warning_list
      @content_warning_list = list
    end

    private

    def load_content_warning_tags
      if content_warning_list_changed? && content_warning_list_was.nil?
        @content_warning_list_was = get_content_warning_tags
      else
        @content_warning_list = get_content_warning_tags
      end
    end

    def reload_content_warning_tags
      self.content_warning_list=get_content_warning_tags
    end

    def get_content_warning_tags
      Tag::List.new(content_warnings.map(&:name))
    end

    def save_content_warning_tags
      return unless content_warning_list_changed?
      save_tags(::ContentWarning, new_list: @content_warning_list, old_list: content_warning_list_was, assoc: content_warnings)
    end
  end
end
