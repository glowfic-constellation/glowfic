class CharactersGallery < ActiveRecord::Base
  belongs_to :character
  belongs_to :gallery
end
