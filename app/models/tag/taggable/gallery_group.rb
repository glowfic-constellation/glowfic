module Tag::Taggable::GalleryGroup
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    define_attribute_method :gallery_group_list
    attribute :gallery_group_list, Tag::List.new

    def gallery_group_list
      @gallery_group_list
    end

    def gallery_group_list=(list)
      list = Tag::List.new(list)
      gallery_group_list_will_change! unless list == gallery_group_list
      @gallery_group_list = list
    end
  end
end
