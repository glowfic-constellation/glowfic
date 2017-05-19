class Template < ActiveRecord::Base
  belongs_to :user, inverse_of: :templates
  has_many :characters, -> { order('LOWER(name) ASC') }

  validates_presence_of :name

  after_destroy :clear_character_templates

  private

  def clear_character_templates
    Character.where(template_id: id).update_all(template_id: nil)
  end
end
