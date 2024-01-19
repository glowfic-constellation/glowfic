class Font < ApplicationRecord
  has_many :post_fonts, dependent: :destroy
  has_many :posts, through: :post_fonts, dependent: :destroy
end
