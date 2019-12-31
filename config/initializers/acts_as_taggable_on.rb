module ActsAsTaggableOn
  module Taggable
    Core.module_eval do
      def find_or_create_tags_from_list_with_context(tag_list, context)
        case context.to_sym
        when :settings
          ::Setting.find_or_create_all_with_like_by_name(tag_list)
        when :labels
          ::Label.find_or_create_all_with_like_by_name(tag_list)
        when :content_warnings
          ::ContentWarning.find_or_create_all_with_like_by_name(tag_list)
        when :gallery_group_ids
          ::GalleryGroup.find_or_create_all_with_like_by_name(tag_list)
        else
          raise ActiveRecord::RecordInvalid, 'Invalid tag type'
        end
      end
    end
  end
end
