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

  def self.characters_list(characters, show_template: false, page_view:, select: [])
    attributes = [:id, :name, :screenname, :user_id]
    attributes += select unless select.empty?
    if page_view == 'list'
      characters = characters.joins(:user)
      attributes += [:pb]
      attributes << :template_id if show_template && !attributes.include?(:template_id)
      pluck_attributes = attributes + [:template_name, 'users.username', 'users.deleted']
      key_attributes   = attributes + [:nickname,      :username,        :user_deleted]
      if show_template
        characters = characters.left_outer_joins(:template)
        pluck_attributes << 'templates.name'
        key_attributes << :template_name
      end
    else
      characters = characters.left_outer_joins(:default_icon)
      attributes += [:url, :keyword]
      pluck_attributes = key_attributes = attributes
    end
    characters.pluck(*pluck_attributes).map{ |char| key_attributes.zip(char).to_h }
  end
end
