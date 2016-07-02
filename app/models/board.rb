class Board < ActiveRecord::Base
  include Viewable

  has_many :posts
  has_many :board_sections
  has_many :board_authors
  has_many :coauthors, class_name: User, through: :board_authors, source: :user
  belongs_to :creator, class_name: User

  validates_presence_of :name, :creator

  after_save :update_author_list

  attr_accessor :coauthor_ids

  def writer_ids
    @ids ||= board_authors.select(&:user_id).map(&:user_id) + [creator_id]
  end

  def writers
    @writers ||= User.find(writer_ids)
  end

  def open_to?(user)
    return true if open_to_anyone?
    writer_ids.include?(user.id)
  end

  def open_to_anyone?
    coauthors.empty?
  end

  def editable_by?(user)
    return false unless user
    return true if user.admin?
    writer_ids.include?(user.id)
  end

  private

  def update_author_list
    return unless coauthor_ids.present?

    updated_ids = (coauthor_ids.uniq - [""]).map(&:to_i)
    existing_ids = board_authors.map(&:user_id)

    BoardAuthor.where(board_id: id, user_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      BoardAuthor.create(board_id: id, user_id: new_id)
    end
  end
end
