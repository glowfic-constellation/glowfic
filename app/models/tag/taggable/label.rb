module Tag::Taggable::Label
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    attr_reader :label_list, :label_list_was, :label_list_changed
    alias_method :label_list_changed?, :label_list_changed

    after_initialize :load_label_tags
    after_save :save_label_tags

    def label_list=(list)
      list = Tag::List.new(list)
      return if list == label_list
      @label_list_changed = true
      @label_list_was = @label_list
      @label_list = list
    end

    private

    def load_label_tags
      if label_list_changed? && label_list_was.nil?
        @label_list_was = get_label_tags
      else
        @label_list = get_label_tags
      end
    end

    def reload_label_tags
      self.label_list=get_label_tags
    end

    def get_label_tags
      Tag::List.new(labels.map(&:name))
    end

    def save_label_tags
      return unless label_list_changed?
      save_tags(::Label, new_list: @label_list, old_list: label_list_was, assoc: labels)
    end
  end
end
