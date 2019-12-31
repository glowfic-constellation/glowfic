ActsAsTaggableOn.tags_table = :aato_tag
ActsAsTaggableOn.taggings_table = :tagging

module ActsAsTaggableOn
  module Taggable
    Core.module_eval do
      def find_or_create_tags_from_list_with_context(tag_list, context)
        case context.to_sym
        when :settings
          ::Taggable::Setting.find_or_create_all_with_like_by_name(tag_list)
        when :labels
          ::Taggable::Label.find_or_create_all_with_like_by_name(tag_list)
        when :content_warnings
          ::Taggable::ContentWarning.find_or_create_all_with_like_by_name(tag_list)
        when :gallery_group_ids
          ::Taggable::GalleryGroup.find_or_create_all_with_like_by_name(tag_list)
        else
          raise ActiveRecord::RecordInvalid, 'Invalid tag type'
        end
      end
    end
  end
end
