class Template < ActiveRecord::Base
  belongs_to :user
  has_many :characters

  def ordered_characters
    characters.sort_by(&:name)
  end
end
