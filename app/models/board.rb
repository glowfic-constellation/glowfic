class Board < ActiveRecord::Base
  include Viewable

  has_many :posts
  has_many :board_sections
  belongs_to :creator, class_name: User
  belongs_to :coauthor, class_name: User

  validates_presence_of :name, :creator

  def writer_ids
    [creator_id, coauthor_id]
  end

  def writers
    @writers ||= User.find(writer_ids)
  end

  def open_to?(user)
    return true if coauthor_id.nil?
    writer_ids.include?(user.id)
  end

  def editable_by?(user)
    return true if user.admin?
    creator_id == user.id
  end
end
