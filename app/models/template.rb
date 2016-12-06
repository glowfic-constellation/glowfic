class Template < ActiveRecord::Base
  belongs_to :user, inverse_of: :templates
  has_many :characters
  has_many :ordered_characters, order: 'LOWER(name)', class_name: 'Character'

  validates_presence_of :name

  before_destroy :clear_character_templates

  private

  def clear_character_templates
    characters.update_all(template_id: nil)
  end
end
