module Tag::Taggable::ContentWarning
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    define_attribute_method :content_warning_list

    after_save :save_content_warning_tags

    def content_warning_list
      @content_warning_list
    end

    def content_warning_list=(list)
      list = Tag::List.new(list)
      content_warning_list_will_change! unless list == content_warning_list
      @content_warning_list = list
    end

    def save_content_warning_tags
      return unless content_warning_list_changed?
      save_tags(::ContentWarning, @content_warning_list, content_warning_list_was)
    end
  end
end
