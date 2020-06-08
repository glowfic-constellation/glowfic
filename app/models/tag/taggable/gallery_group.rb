module Tag::Taggable::GalleryGroup
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    attr_reader :gallery_group_list, :gallery_group_list_was, :gallery_group_list_changed
    alias_method :gallery_group_list_changed?, :gallery_group_list_changed

    after_initialize :load_gallery_group_tags
    after_save :save_gallery_group_tags

    def gallery_group_list=(list)
      list = Tag::List.new(list)
      return if list == gallery_group_list
      @gallery_group_list_changed = true
      @gallery_group_list_was = @gallery_group_list
      @gallery_group_list = list
    end

    private

    def load_gallery_group_tags
      if gallery_group_list_changed? && gallery_group_list_was.nil?
        @gallery_group_list_was = get_gallery_group_tags
      else
        @gallery_group_list = get_gallery_group_tags
      end
    end

    def reload_gallery_group_tags
      self.gallery_group_list=get_gallery_group_tags
    end

    def get_gallery_group_tags
      Tag::List.new(gallery_groups.map(&:name))
    end

    def save_gallery_group_tags
      return unless gallery_group_list_changed?
      save_tags(::GalleryGroup, new_list: @gallery_group_list, old_list: gallery_group_list_was, assoc: gallery_groups)
    end
  end
end
