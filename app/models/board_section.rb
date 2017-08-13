class BoardSection < ActiveRecord::Base
  include Orderable
  include Presentable

  belongs_to :board, inverse_of: :board_sections
  has_many :posts, inverse_of: :section, foreign_key: :section_id

  validates_presence_of :name, :board

  attr_accessible :status, :board, :board_id, :name, :section_order

  after_destroy :clear_post_values

  private

  def clear_post_values
    Post.where(section_id: id).each do |post|
      post.section_id = nil
      post.save
    end
  end

  def ordered_attributes
    [:board_id]
  end
end
