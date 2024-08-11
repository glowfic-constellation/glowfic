# frozen_string_literal: true
class IndexSection < ApplicationRecord
  include Orderable

  belongs_to :index, inverse_of: :index_sections, optional: false
  has_many :index_posts, inverse_of: :index_section, dependent: false # This is handled in callbacks
  has_many :posts, through: :index_posts

  validates :name, presence: true

  after_destroy :clear_index_post_values

  scope :ordered, -> { order(section_order: :asc) }

  private

  def clear_index_post_values
    IndexPost.where(index_section_id: id).find_each do |post|
      post.update(index_section_id: nil)
    end
  end

  def ordered_attributes
    [:index_id]
  end
end
