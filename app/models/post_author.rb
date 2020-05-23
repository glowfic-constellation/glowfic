class PostAuthor < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :post }

  def opt_out_of_owed(user)
    return unless (author = author_for(user))
    author.destroy and return true unless author.joined?
    author.update(can_owe: false)
  end

  def opt_in_to_owed(user)
    return unless (author = author_for(user))
    return if author.can_owe?
    author.update(can_owe: true)
  end
end
