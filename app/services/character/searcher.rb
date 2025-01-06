# frozen_string_literal: true
class Character::Searcher < Generic::Searcher
  attr_reader :templates, :users

  def initialize(search=Character.unscoped, templates: [], users: [])
    @templates = templates
    @users = users
    super(search)
  end

  def search(params, page: 1)
    search_users(params[:author_id]) if params[:author_id].present?

    if params[:template_id].present?
      search_templates(params[:template_id])
    elsif params[:author_id].present?
      select_templates(params[:author_id])
    end

    search_settings(params[:setting_id]) if params[:setting_id].present?
    search_facecasts(params[:pb]) if params[:pb].present?
    search_names(params) if params[:name].present?

    @search_results.ordered.paginate(page: page) unless errors.present?
    @search_results
  end

  private

  def search_users(user_id)
    @users = User.active.where(id: user_id)
    if @users.present?
      @search_results = @search_results.where(user_id: user_id)
    else
      errors.add(:user, "could not be found.")
    end
  end

  def search_templates(template_id)
    template = Template.find_by(id: template_id)
    if template.present?
      if @users.blank? || template.user_id == @users.first.id
        @search_results = @search_results.where(template_id: template_id)
        @templates = [template]
      else
        errors.add(:base, "The specified author and template do not match; template filter will be ignored.")
        @templates = []
      end
    else
      errors.add(:template, "could not be found.")
      @templates = []
    end
  end

  def search_settings(setting_id)
    @settings = Setting.where(id: setting_id)
    character_ids = CharacterTag.where(tag_id: setting_id).pluck(:character_id)
    @search_results = @search_results.where(id: character_ids)
  end

  def select_templates(user_id)
    @templates = Template.where(user_id: user_id).ordered.limit(25)
  end

  def search_facecasts(facecast)
    @search_results = @search_results.where('pb ILIKE ?', '%' + facecast.to_s + '%')
  end

  def search_names(params)
    where_calc = []
    where_calc << "name ILIKE ?" if params[:search_name].present?
    where_calc << "screenname ILIKE ?" if params[:search_screenname].present?
    where_calc << "template_name ILIKE ?" if params[:search_nickname].present?
    where_calc << 'id in (SELECT character_id from character_aliases WHERE name ILIKE ?)' if params[:search_aliases].present?

    @search_results = @search_results.where(where_calc.join(' OR '), *(["%#{params[:name]}%"] * where_calc.length))
  end
end
