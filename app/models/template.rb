class Template < ActiveRecord::Base
  belongs_to :user
  has_many :characters

  validates_presence_of :name

  before_destroy :clear_character_templates

  def ordered_characters
    characters.sort_by(&:name)
  end

  private

  def clear_character_templates
    characters.update_all(template_id: nil)
  end
end
