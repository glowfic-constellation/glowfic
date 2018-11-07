class Character::Searcher < Generic::Searcher
  attr_reader :templates, :users

  def initialize(search=Character.unscoped, templates:, users:)
    @templates = templates
    @users = users
    super(search)
  end

  def search(params)
    @search_results = Character.unscoped

    if params[:author_id].present?
      @users = User.active.where(id: params[:author_id])
      if @users.present?
        @search_results = @search_results.where(user_id: params[:author_id])
      else
        flash.now[:error] = "The specified author could not be found."
      end
    end

    if params[:template_id].present?
      @templates = Template.where(id: params[:template_id])
      template = @templates.first
      if template.present?
        if @users.present? && template.user_id != @users.first.id
          flash.now[:error] = "The specified author and template do not match; template filter will be ignored."
          @templates = []
        else
          @search_results = @search_results.where(template_id: params[:template_id])
        end
      else
        flash.now[:error] = "The specified template could not be found."
      end
    elsif params[:author_id].present?
      @templates = Template.where(user_id: params[:author_id]).ordered.limit(25)
    end

    if params[:name].present?
      where_calc = []
      where_calc << "name ILIKE ?" if params[:search_name].present?
      where_calc << "screenname ILIKE ?" if params[:search_screenname].present?
      where_calc << "nickname ILIKE ?" if params[:search_nickname].present?

      @search_results = @search_results.where(where_calc.join(' OR '), *(['%' + params[:name].to_s + '%'] * where_calc.length))
    end

    @search_results = @search_results.ordered.paginate(page: page)
  end
end
