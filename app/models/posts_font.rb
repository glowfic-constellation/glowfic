class PostsFont < ApplicationRecord
  belongs_to :post, inverse_of: :posts_fonts, optional: false
  belongs_to :font, inverse_of: :posts_fonts, optional: false
end
