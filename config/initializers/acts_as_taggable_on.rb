ActsAsTaggableOn.tags_table = :aato_tag
ActsAsTaggableOn.taggings_table = :tagging

module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    acts_as_ordered_taggable_on :settings

    has_many :parents, through: :taggings, source: :tag, dependent: :destroy
    has_many :child_taggings, class_name: 'ActsAsTaggableOn::Tagging', dependent: :destroy
    has_many :children, through: :child_taggings, source: :taggable, source_type: "ActsAsTaggableOn::Tag", dependent: :destroy

    has_many :ownership_taggings, -> { where(taggable_type: 'User') },
      class_name: 'ActsAsTaggableOn::Tagging', foreign_key: :tag_id, dependent: :destroy
    has_many :owners, through: :ownership_taggings, source: :taggable, source_type: 'User', dependent: :destroy

    def self.for_context(context)
      joins(:child_taggings).
        where(["#{ActsAsTaggableOn.taggings_table}.context = ?", context]).
        select("DISTINCT #{ActsAsTaggableOn.tags_table}.*")
    end

    def editable_by?(user)
      return false unless user
      return true if deletable_by?(user)
      return true if user.has_permission?(:edit_tags)
    end

    def deletable_by?(user)
      return false unless user
      return true if user.has_permission?(:delete_tags)
      owner_ids.include?(user.id)
    end
  end
end
