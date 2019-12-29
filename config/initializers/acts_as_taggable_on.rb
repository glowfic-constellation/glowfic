ActsAsTaggableOn.tags_table = :aato_tag
ActsAsTaggableOn.taggings_table = :tagging

module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    acts_as_ordered_taggable_on :settings
  end
end
