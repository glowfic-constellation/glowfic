module Owable
  extend ActiveSupport::Concern

  included do
    has_many :post_authors, inverse_of: :post, class_name: 'Post::Author', dependent: :destroy
    has_many :authors, class_name: 'User', through: :post_authors, source: :user, dependent: :destroy

    # list of users who owe replies on this post, whether or not they have posted yet
    has_many :tagging_post_authors, -> { where(can_owe: true) }, class_name: 'Post::Author', inverse_of: :post
    has_many :tagging_authors, class_name: 'User', through: :tagging_post_authors, source: :user, dependent: :destroy

    # quick way to pull author list without calculating from post + replies
    has_many :joined_post_authors, -> { where(joined: true) }, class_name: 'Post::Author', inverse_of: :post
    has_many :joined_authors, class_name: 'User', through: :joined_post_authors, source: :user, dependent: :destroy

    # used in the post#write UI to handle inviting users
    has_many :unjoined_post_authors, -> { where(joined: false) }, class_name: 'Post::Author', inverse_of: :post
    has_many :unjoined_authors, class_name: 'User', through: :unjoined_post_authors, source: :user, dependent: :destroy

    after_create :add_creator_to_authors
    after_save :update_board_cameos

    validate :valid_coauthors, on: :create
    validate :valid_new_coauthors, on: :update

    attr_accessor :private_note

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

    def author_for(user)
      post_authors.find_by(user_id: user.id)
    end

    private

    def add_creator_to_authors
      if author_ids.include?(user_id)
        author_for(user).update(joined: true, joined_at: created_at, private_note: private_note)
      else
        post_authors.create(user: user, joined: true, joined_at: created_at, private_note: private_note)
      end
    end

    def update_board_cameos
      return unless board.authors_locked?

      # adjust for the fact that the associations are managed separately
      all_authors = authors + unjoined_authors + joined_authors + tagging_authors
      # check board authors rather than authors to avoid issues with weird association caching
      new_cameos = all_authors.uniq.map(&:id) - board.board_authors.map(&:user_id)
      return if new_cameos.empty?
      new_cameos.each { |author| board.board_authors.create!(user_id: author, cameo: true) }
    end

    def valid_coauthors
      return if self.unjoined_authors.empty?
      return if self.user.user_ids_uninteractable.empty? && self.authors.empty?
      self.unjoined_authors.each_with_index do |user, i|
        next if user.user_ids_uninteractable.empty?
        authors = self.user + self.unjoined_authors[i + 1, -1]
        authors.each do |author|
          unless author.can_interact_with?(unjoined)
            errors.add(:post_author, "cannot be added")
            break
          end
        end
      end
    end

    def valid_new_coauthors
      return if self.unjoined_authors.empty?
      return if self.user.user_ids_uninteractable.empty? && self.authors.length == 1
      new_ids = self.unjoined_post_authors.reject(&:persisted?).pluck(:user_id)
      new_users = User.where(id: new_ids)
      new_users.each_with_index do |unjoined, i|
        next if unjoined.user_ids_uninteractable.empty?
        authors = User.where(self.post_authors.select(&:persisted?).pluck(:user_id))
        unchecked = new_users[i + 1, -1]
        authors += unchecked if unchecked.present?
        authors.each do |author|
          unless author.can_interact_with?(unjoined)
            errors.add(:post_author, "cannot be added")
            break
          end
        end
      end
    end
  end
end
