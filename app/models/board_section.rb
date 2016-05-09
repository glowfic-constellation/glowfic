class BoardSection < ActiveRecord::Base
  belongs_to :board, inverse_of: :board_sections
  has_many :posts, inverse_of: :section, foreign_key: :section_id

  validates_presence_of :name, :board

  attr_accessible :status, :board_id, :name, :section_order

  before_create :autofill_order

  private

  def autofill_order
    previous_section = BoardSection.where(board_id: board_id).select(:section_order).order('id desc').first.try(:section_order)
    previous_section ||= -1
    self.section_order = previous_section + 1
  end
end
