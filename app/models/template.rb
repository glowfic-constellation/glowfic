class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates
  has_many :characters, -> { order('LOWER(name) ASC') }, inverse_of: :template

  validates_presence_of :name, :user

  after_destroy :clear_character_templates

  def plucked_characters
    characters.pluck("id, concat_ws(' | ', name, template_name, screenname)")
  end

  private

  def clear_character_templates
    Character.where(template_id: id).update_all(template_id: nil)
  end
end
