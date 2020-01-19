class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }

  def plucked_characters
    characters.pluck(Arel.sql("id, concat_ws(' | ', name, template_name, screenname)"))
  end

  def self.settings_info(characters)
    settings = characters.joins(:settings).group(:id)
    sql = Arel.sql('ARRAY_AGG(tags.id ORDER BY character_tags.id ASC) AS setting_ids, ARRAY_AGG(tags.name ORDER BY character_tags.id ASC)')
    settings = settings.pluck(:id, sql)
    settings.map{ |i| [i[0], i[1].zip(i[2])] }.to_h
  end

  def self.characters_list(characters, show_template=false)
    characters = characters.left_outer_joins(:template) if show_template
    attributes = [:id, :name, :template_name, :screenname, :pb, :user_id, 'users.username', Arel.sql('users.deleted as user_deleted')]
    attributes += ['templates.id', 'templates.name'] if show_template
    characters.joins(:user).pluck(*attributes)
  end
end
