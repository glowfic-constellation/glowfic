# frozen_string_literal: true
class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :tag, inverse_of: :post_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :content_warning, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :label, foreign_key: :tag_id, inverse_of: :post_tags, optional: true

  validates :post, uniqueness: { scope: :tag }

  # a join built through an unsaved post can be saved from the tag's side first
  # (e.g. via an NPC's settings), before the post's own save syncs this foreign key
  before_create -> { self.post_id ||= post&.id }
end
