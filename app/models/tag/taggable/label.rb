module Tag::Taggable::Label
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    define_attribute_method :label_list

    after_initialize :load_label_tags
    after_save :save_label_tags

    def label_list
      @label_list
    end

    def label_list=(list)
      list = Tag::List.new(list)
      return if list == label_list
      @label_list_changed = true
      @label_list_was = @label_list
      @label_list = list
    end

    def label_list_changed?
      @label_list_changed
    end

    private

    def load_label_tags
      @label_list = get_label_tags
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
