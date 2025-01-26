# frozen_string_literal: true
class BoardSection < ApplicationRecord
  include Orderable
  include Presentable

  belongs_to :board, inverse_of: :board_sections, optional: false
  has_many :posts, inverse_of: :section, foreign_key: :section_id, dependent: false # This is handled in callbacks

  validates :name, presence: true, length: { maximum: 255 }

  after_destroy :clear_section_ids

  scope :ordered, -> { order(section_order: :asc) }

  private

  def clear_section_ids
    # if the parent board is already being destroyed, we'll handle this in board#move_posts_to_sandbox
    # this avoids intermediate Post callbacks triggered by the section_id change that have no board present
    return if destroyed_by_association&.active_record == Board
    UpdateModelJob.perform_later(Post.to_s, { section_id: id }, { section_id: nil }, audited_user_id)
  end

  def ordered_attributes
    [:board_id]
  end
end
