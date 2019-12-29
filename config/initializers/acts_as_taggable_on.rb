ActsAsTaggableOn.tags_table = :aato_tag
ActsAsTaggableOn.taggings_table = :tagging

module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    acts_as_ordered_taggable_on :settings

    has_many :parents, through: :taggings, source: :tag, dependent: :destroy
    has_many :child_taggings, -> { where(taggable_type: 'ActsAsTaggableOn::Tag') },
      class_name: 'ActsAsTaggableOn::Tagging', foreign_key: :tag_id, dependent: :destroy
    has_many :children, through: :child_taggings, source: :taggable, source_type: "ActsAsTaggableOn::Tag", dependent: :destroy

    has_many :ownership_taggings, -> { where(taggable_type: 'User') },
      class_name: 'ActsAsTaggableOn::Tagging', foreign_key: :tag_id, dependent: :destroy
    has_many :owners, through: :ownership_taggings, source: :taggable, source_type: 'User', dependent: :destroy
  end
end
