class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template

  validates :name, presence: true

  after_destroy :clear_character_templates

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }

  def plucked_characters
    characters.pluck("id, concat_ws(' | ', name, template_name, screenname)")
  end

  private

  def clear_character_templates
    Character.where(template_id: id).update_all(template_id: nil)
  end
end
