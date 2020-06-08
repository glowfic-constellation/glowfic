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
      label_list_will_change! unless list == label_list
      @label_list = list
    end

    private

    def load_label_tags
      @label_list = Tag::List.new(labels.map(&:name))
    end

    def save_label_tags
      return unless label_list_changed?
      save_tags(::Label, @label_list, label_list_was)
    end
  end
end
