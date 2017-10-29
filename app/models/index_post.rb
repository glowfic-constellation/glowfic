class IndexPost < ApplicationRecord
  include Orderable

  belongs_to :post, inverse_of: :index_posts
  belongs_to :index, inverse_of: :index_posts
  belongs_to :index_section, inverse_of: :index_posts

  validates_presence_of :post, :index
  validate :section_in_index

  before_validation :populate_index

  private

  def ordered_attributes
    [:index_section_id, :index_id]
  end

  def populate_index
    return if index_id.present?
    return unless index_section_id.present?
    self.index_id = index_section.index_id
  end

  def section_in_index
    return unless index_id.present?
    return unless index_section.present?
    return if index_section.index_id == index_id
    errors.add(:index_section, "does not belong to the index")
  end
end
