module CharacterHelper
  def settings_info(characters)
    settings = characters.joins(:settings).group(:id)
    settings = settings.pluck(:id, Arel.sql('ARRAY_AGG(tags.id ORDER BY character_tags.id ASC) AS setting_ids, ARRAY_AGG(tags.name ORDER BY character_tags.id ASC)'))
    settings.map{ |i| [i[0], i[1].zip(i[2])] }.to_h
  end

  def characters_list(characters, show_template)
    characters = characters.left_outer_joins(:template) if show_template
    attributes = [:id, :name, :template_name, :screenname, :pb, :user_id, 'users.username', Arel.sql('users.deleted as user_deleted')]
    attributes += ['templates.id', 'templates.name'] if show_template
    characters.joins(:user).pluck(*attributes)
  end
end
