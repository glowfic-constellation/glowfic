class NewsView < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :news, optional: false

  validates :user, uniqueness: { scope: :news }
end
