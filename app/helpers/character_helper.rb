module CharacterHelper
  def settings_info(characters)
    settings = characters.joins(:settings).group(:id)
    sql = Arel.sql('ARRAY_AGG(tags.id ORDER BY character_tags.id ASC) AS setting_ids, ARRAY_AGG(tags.name ORDER BY character_tags.id ASC)')
    settings = settings.pluck(:id, sql)
    settings.map{ |i| [i[0], i[1].zip(i[2])] }.to_h
  end

  def characters_list(characters, show_template)
    characters = characters.left_outer_joins(:template) if show_template
    attributes = [:id, :name, :nickname, :screenname, :pb, :cluster, :user_id, 'users.username', Arel.sql('users.deleted as user_deleted')]
    attributes += ['templates.id', 'templates.name'] if show_template
    characters.joins(:user).pluck(*attributes)
  end

  def character_menu_link(link_params)
    link_params = params.permit(:character_split, :retired, :view).to_h.merge(link_params)
    url_for(**link_params.symbolize_keys)
  end
end
