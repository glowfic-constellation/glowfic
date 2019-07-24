class IndexSection < ApplicationRecord
  include Orderable

  belongs_to :index, inverse_of: :index_sections, optional: false
  has_many :index_posts, inverse_of: :index_section, dependent: :destroy
  has_many :posts, through: :index_posts, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(section_order: :asc) }

  private

  def ordered_attributes
    [:index_id]
  end
end
