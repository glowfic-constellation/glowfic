class Board < ActiveRecord::Base
  include Viewable

  has_many :posts
  has_many :board_sections
  has_many :board_authors
  belongs_to :creator, class_name: User
  has_many :coauthors, class_name: User, through: :board_authors, source: :user do
    def cameos
      merge(BoardAuthor.cameo)
    end
  end

  validates_presence_of :name, :creator

  after_save :update_author_list

  attr_accessor :coauthor_ids, :cameo_ids

  def writers
    @writers ||= coauthors + [creator]
  end

  def open_to?(user)
    return true if open_to_anyone?
    return true if creator_id == user.id
    board_authors.select(&:user_id).map(&:user_id).include?(user.id)
  end

  def open_to_anyone?
    coauthors.empty?
  end

  def editable_by?(user)
    return false unless user
    return true if user.admin?
    return true if creator_id == user.id
    coauthors.select(&:id).map(&:id).include?(user.id)
  end

  def ordered_items
    return @items unless @items.nil?
    @items = posts.where(section_id: nil).to_a
    @items += board_sections.to_a
    @items.sort_by!{ |i| i.section_order }
  end

  private

  def update_author_list
    coauthor_ids = self.coauthor_ids || []
    cameo_ids = self.cameo_ids || []

    updated_ids = (coauthor_ids.uniq - [""]).map(&:to_i)
    existing_ids = coauthors.map(&:id)

    BoardAuthor.where(board_id: id, user_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      BoardAuthor.create(board_id: id, user_id: new_id)
    end

    updated_ids = (cameo_ids.uniq - [""]).map(&:to_i)
    existing_ids = coauthors.cameos.map(&:id)

    BoardAuthor.where(board_id: id, user_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      BoardAuthor.create(board_id: id, user_id: new_id, cameo: true)
    end
  end
end
