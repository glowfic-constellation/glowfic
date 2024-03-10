class PostFont < ApplicationRecord
  belongs_to :post, inverse_of: :post_fonts, optional: false
  belongs_to :font, inverse_of: :post_fonts, optional: false

  validates :post, uniqueness: { scope: :font }
end
