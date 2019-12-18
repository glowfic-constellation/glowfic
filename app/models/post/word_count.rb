module Post::WordCount
  extend ActiveSupport::Concern

  included do
    def total_word_count
      return word_count unless replies.exists?
      word_count + Posts::WordCount.replies_word_count(replies)
    end

    def word_count_for(user)
      sum = 0
      sum = word_count if user_id == user.id
      return sum unless replies.where(user_id: user.id).exists?
      sum + Posts::WordCount.replies_word_count(replies.where(user_id: user.id))
    end

    # only returns for authors who have written in the post (it's zero for authors who have not joined)
    def author_word_counts
      authors_map = joined_authors.map { |author| [!author.deleted? ? author.username : '(deleted user)', word_count_for(author)] }
      authors_map.sort_by(&:last).reverse
    end
  end

  def self.replies_word_count(replies)
    contents = replies.pluck(:content)
    contents.map!{ |text| text.split.size }
    contents.reduce(:+).to_i
  end
end
