class Board < ActiveRecord::Base
  include Viewable

  ID_SITETESTING = 4

  has_many :posts
  has_many :board_sections
  has_many :favorites, as: :favorite, dependent: :destroy
  belongs_to :creator, class_name: User

  has_many :board_authors
  has_many :board_coauthors, class_name: BoardAuthor, conditions: {cameo: false}
  has_many :coauthors, class_name: User, through: :board_coauthors, source: :user
  has_many :board_cameos, class_name: BoardAuthor, conditions: {cameo: true}
  has_many :cameos, class_name: User, through: :board_cameos, source: :user

  validates_presence_of :name, :creator

  after_destroy :move_posts_to_sandbox

  def writers
    @writers ||= coauthors + [creator]
  end

  def open_to?(user)
    return true if open_to_anyone?
    return true if creator_id == user.id
    board_authors.where(user_id: user.id).exists?
  end

  def open_to_anyone?
    !board_authors.exists?
  end

  def editable_by?(user)
    return false unless user
    return true if user.admin?
    return true if creator_id == user.id
    board_coauthors.where(user_id: user.id).exists?
  end

  def ordered_items
    return @items unless @items.nil?
    @items = posts.where(section_id: nil).to_a
    @items += board_sections.to_a
    @items.sort_by!{ |i| i.section_order }
  end

  private

  def move_posts_to_sandbox
    # TODO don't hard code sandbox board_id
    # TODO / WARNING this doesn't trigger callbacks
    posts.update_all(board_id: 3)
  end
end
