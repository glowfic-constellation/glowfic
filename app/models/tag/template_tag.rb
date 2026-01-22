# frozen_string_literal: true
class Tag::TemplateTag < ApplicationRecord
  self.table_name = 'template_tags'

  belongs_to :template, inverse_of: :template_tag, optional: false
  belongs_to :tag, inverse_of: :template_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :character_group, foreign_key: :tag_id, inverse_of: :template_tags, optional: true # This is (currently) required but see above

  validates :template, uniqueness: true
end
