class BoardSection < ActiveRecord::Base
  belongs_to :board, inverse_of: :board_sections
  has_many :posts, inverse_of: :section, foreign_key: :section_id

  validates_presence_of :name, :board

  attr_accessible :status, :board, :board_id, :name, :section_order

  before_create :autofill_order
  after_destroy :clear_post_values, :reorder_others

  private

  def autofill_order
    previous_section = BoardSection.where(board_id: board_id).select(:section_order).order('section_order desc').first.try(:section_order)
    previous_section ||= -1
    self.section_order = previous_section + 1
  end

  def clear_post_values
    posts = Post.where(section_id: id)
    posts.update_all(section_id: nil, section_order: nil)
  end

  def reorder_others
    other_sections = BoardSection.where(board_id: board_id).order('section_order asc')
    return unless other_sections.present?
    other_sections.each_with_index do |section, index|
      section.section_order = index
      section.save
    end
  end
end
