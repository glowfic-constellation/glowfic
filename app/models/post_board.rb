# frozen_string_literal: true
class PostBoard < ApplicationRecord
  include Orderable

  belongs_to :post, inverse_of: :post_boards, optional: false
  belongs_to :board, inverse_of: :post_boards, optional: false
  belongs_to :section, class_name: 'BoardSection', inverse_of: :post_boards, optional: true

  validates :post, uniqueness: { scope: :board }
  validate :section_in_board
  validate :user_writes_in_board

  after_create :sync_board_cameos

  scope :main, -> { where(is_main: true) }
  scope :ordered_in_section, -> { order(section_order: :asc) }

  private

  def ordered_attributes
    [:section_id, :board_id]
  end

  def section_in_board
    return if section.nil?
    return if section.board_id == board_id
    errors.add(:section, "must belong to this continuity")
  end

  def user_writes_in_board
    return unless board && post&.user
    return unless new_record? || board_id_changed?
    return if board.open_to?(post.user)
    errors.add(:board, "is invalid – the post's author must be able to write in it")
  end

  def sync_board_cameos
    return if is_main?
    post.send(:cameo_authors_into, board)
  end
end
