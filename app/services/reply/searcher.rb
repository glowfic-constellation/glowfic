class Reply::Searcher < Generic::Searcher
  attr_reader :templates, :users

  def initialize(search=Reply.unscoped, templates:, users:)
    @templates = templates
    @users = users
    super(search)
  end

  def search(params, post:, page: 1)
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where(character_id: params[:character_id]) if params[:character_id].present?
    @search_results = @search_results.where(icon_id: params[:icon_id]) if params[:icon_id].present?

    search_content(params[:subj_content]) if params[:subj_content].present?
    sort(params[:sort], params[:subject_content]) if params[:sort].present?
    search_posts(post, params[:board_id]) if post || params[:board_id].present?
    search_templates(params[:template_id]) if params[:template_id].present?
    select_templates(params[:author_id]) if params[:author_id].present? && params[:template_id].blank?

    @search_results = @search_results
      .select('replies.*, characters.name, characters.screenname, users.username, users.deleted as user_deleted')
      .visible_to(current_user)
      .joins(:user)
      .left_outer_joins(:character)
      .paginate(page: page)
      .includes(:post)

    @search_results = @search_results.where.not(post_id: current_user.hidden_posts) if logged_in? && !params[:show_blocked]

    return @search_results if params[:condensed]

    @search_results = @search_results
      .select('icons.keyword, icons.url')
      .left_outer_joins(:icon)
    @search_results
  end

  def search_content(content)
    @search_results = @search_results.search(content).with_pg_search_highlight
    exact_phrases = content.scan(/"([^"]*)"/)
    return unless exact_phrases.present?
    exact_phrases.each do |phrase|
      phrase = phrase.first.strip
      next if phrase.blank?
      @search_results = @search_results.where("replies.content ILIKE ?", "%#{phrase}%")
    end
  end

  def sort(sort, content)
    append_rank = content.present? ? ', rank DESC' : ''
    if sort == 'created_new'
      @search_results = @search_results.except(:order).order('replies.created_at DESC' + append_rank)
    elsif sort == 'created_old'
      @search_results = @search_results.except(:order).order('replies.created_at ASC' + append_rank)
    elsif content.blank?
      @search_results = @search_results.order('replies.created_at DESC')
    end
  end

  def search_posts(post, board_id)
    if post
      @search_results = @search_results.where(post_id: post.id)
    elsif board_id.present?
      post_ids = Post.where(board_id: board_id).pluck(:id)
      @search_results = @search_results.where(post_id: post_ids)
    end
  end

  def search_templates(template_id)
    @templates = Template.where(id: template_id)
    return unless @templates.first.present?
    character_ids = Character.where(template_id: @templates.first.id).pluck(:id)
    @search_results = @search_results.where(character_id: character_ids)
  end

  def select_templates
    @templates = @templates.where(user_id: params[:author_id])
  end
end
