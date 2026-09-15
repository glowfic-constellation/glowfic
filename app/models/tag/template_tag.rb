# frozen_string_literal: true
class Tag::TemplateTag < ApplicationRecord
  # define this scope here or Orderable will redefine it
  scope :ordered, -> { order(section_order: :asc) }
  scope :ordered_manually, -> { ordered }
  include Orderable

  self.table_name = 'template_tags'

  belongs_to :template, inverse_of: :template_tag, optional: false
  belongs_to :tag, inverse_of: :template_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :character_group, foreign_key: :tag_id, inverse_of: :template_tags, optional: true # This is (currently) required but see above

  validates :template, uniqueness: true

  def ordered_attributes
    [:template_id]
  end
end
