class Character::Searcher < Generic::Searcher
  def initialize(search=Character.unscoped, templates:, users:)
    super
  end

  def search(params, page: 1)
    search_users(params[:author_id]) if params[:author_id].present?
    search_templates(params[:template_id], params[:author_id]) if params[:template_id].present? || params[:author_id].present?
    search_names(params) if params[:name].present?
    @search_results.ordered.paginate(page: page, per_page: 25) unless errors.present?
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
      if @users.present? && template.user_id != @users.first.id
        errors.add(:base, "The specified author and template do not match; template filter will be ignored.")
        @templates = []
      else
        @search_results = @search_results.where(template_id: template_id)
        @templates = [template]
      end
    else
      errors.add(:template, "could not be found.")
      @templates = []
    end
  end

  def select_templates(user_id)
    @templates = Template.where(user_id: user_id).ordered.limit(25)
  end

  def search_names(params)
    where_calc = []
    where_calc << "name ILIKE ?" if params[:search_name].present?
    where_calc << "screenname ILIKE ?" if params[:search_screenname].present?
    where_calc << "nickname ILIKE ?" if params[:search_nickname].present?

    @search_results = @search_results.where(where_calc.join(' OR '), *(['%' + params[:name].to_s + '%'] * where_calc.length))
  end
end
