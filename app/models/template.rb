class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }

  def plucked_characters
    characters.pluck(Arel.sql("id, concat_ws(' | ', name, template_name, screenname)"))
  end
end
