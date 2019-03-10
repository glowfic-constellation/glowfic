class NewsView < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :news, optional: false
end
