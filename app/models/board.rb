class Board < ActiveRecord::Base
  include Presentable
  include Viewable

  ID_SITETESTING = 4

  has_many :posts
  has_many :board_sections, dependent: :destroy
  has_many :favorites, as: :favorite, dependent: :destroy
  belongs_to :creator, class_name: User

  has_many :board_authors
  has_many :board_coauthors, -> { where(cameo: false) }, class_name: BoardAuthor
  has_many :coauthors, class_name: User, through: :board_coauthors, source: :user
  has_many :board_cameos, -> { where(cameo: true) }, class_name: BoardAuthor
  has_many :cameos, class_name: User, through: :board_cameos, source: :user

  validates_presence_of :name, :creator

  after_destroy :move_posts_to_sandbox

  def writers
    @writers ||= coauthors + [creator]
  end

  def open_to?(user)
    return false unless user
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

  private

  def move_posts_to_sandbox
    # TODO don't hard code sandbox board_id
    # TODO / WARNING this doesn't trigger callbacks
    posts.update_all(board_id: 3, section_id: nil)
  end

  def fix_ordering
    # this should ONLY be called by an admin for emergency fixes
    board_sections.order('section_order asc').each_with_index do |section, index|
      next if section.section_order == index
      section.update_attribute(:section_order, index)
    end
    posts.where(section_id: nil).order('section_order asc').each_with_index do |post, index|
      next if post.section_order == index
      post.update_attribute(:section_order, index)
    end
  end
end
