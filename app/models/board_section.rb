class BoardSection < ActiveRecord::Base
  belongs_to :board, inverse_of: :board_sections
  has_many :posts, inverse_of: :section, foreign_key: :section_id
  validates_presence_of :name, :board

  attr_accessible :status, :board_id, :name, :section_order
end
