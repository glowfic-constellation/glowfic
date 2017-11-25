class FlatPost < ApplicationRecord
  belongs_to :post, inverse_of: :flat_post, optional: false
end
