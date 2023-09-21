class Board < ApplicationRecord
  include Presentable
  include Viewable

  ID_SANDBOX = 3
  ID_SITETESTING = 4

  has_many :posts, inverse_of: :continuity, dependent: false # This is handled in callbacks
  has_many :board_sections, inverse_of: :continuity, dependent: :destroy
  has_many :favorites, as: :favorite, inverse_of: :favorite, dependent: :destroy
  has_many :views, class_name: 'BoardView', inverse_of: :continuity, dependent: :destroy
  belongs_to :creator, class_name: 'User', inverse_of: false, optional: false

  has_many :board_authors, inverse_of: :continuity, dependent: :destroy
  has_many :authors, class_name: 'User', through: :board_authors, source: :user, dependent: :destroy
  has_many :board_writers, -> { where(cameo: false) }, class_name: 'BoardAuthor', inverse_of: :continuity, dependent: :destroy
  has_many :writers, class_name: 'User', through: :board_writers, source: :user, dependent: :destroy
  has_many :board_cameos, -> { where(cameo: true) }, class_name: 'BoardAuthor', inverse_of: :continuity, dependent: :destroy
  has_many :cameos, class_name: 'User', through: :board_cameos, source: :user, dependent: :destroy
  has_many :coauthors, ->(continuity) { where.not(id: continuity.creator_id) }, class_name: 'User',
    through: :board_writers, source: :user, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  after_create :add_creator_to_authors
  after_destroy :move_posts_to_sandbox

  scope :ordered, -> { order(pinned: :desc, name: :asc) }

  def open_to?(user)
    return false unless user
    return false if user.read_only?
    return true unless self.authors_locked?
    return true if creator_id == user.id
    board_authors.where(user_id: user.id).exists?
  end

  def editable_by?(user)
    return false unless user
    return true if creator_id == user.id
    return true if user.has_permission?(:edit_continuities)
    return false if creator.deleted?
    board_writers.where(user_id: user.id).exists?
  end

  def ordered?
    authors_locked? || board_sections.exists?
  end

  private

  def move_posts_to_sandbox
    UpdateModelJob.perform_later(Post.to_s, { board_id: id }, { board_id: ID_SANDBOX, section_id: nil }, audited_user_id)
  end

  def add_creator_to_authors
    board_authors.create!(user: creator)
  end

  def fix_ordering
    # this should ONLY be called by an admin for emergency fixes
    board_sections.ordered.each_with_index do |section, index|
      next if section.section_order == index
      section.update_columns(section_order: index) # rubocop:disable Rails/SkipsModelValidations
    end
    posts.where(section_id: nil).ordered_in_section.each_with_index do |post, index|
      next if post.section_order == index
      post.update_columns(section_order: index) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
