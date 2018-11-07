class Reply::Searcher < Generic::Searcher
  attr_reader :templates, :users

  def initialize(search=Reply.unscoped, templates:, users:)
    @templates = templates
    @users = users
    super(search)
  end

  def search(params, post:, page:)
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where(character_id: params[:character_id]) if params[:character_id].present?
    @search_results = @search_results.where(icon_id: params[:icon_id]) if params[:icon_id].present?

    if params[:subj_content].present?
      @search_results = @search_results.search(params[:subj_content]).with_pg_search_highlight
      exact_phrases = params[:subj_content].scan(/"([^"]*)"/)
      if exact_phrases.present?
        exact_phrases.each do |phrase|
          phrase = phrase.first.strip
          next if phrase.blank?
          @search_results = @search_results.where("replies.content ILIKE ?", "%#{phrase}%")
        end
      end
    end

    append_rank = params[:subj_content].present? ? ', rank DESC' : ''
    if params[:sort] == 'created_new'
      @search_results = @search_results.except(:order).order('replies.created_at DESC' + append_rank)
    elsif params[:sort] == 'created_old'
      @search_results = @search_results.except(:order).order('replies.created_at ASC' + append_rank)
    elsif params[:subj_content].blank?
      @search_results = @search_results.order('replies.created_at DESC')
    end

    if @post
      @search_results = @search_results.where(post_id: @post.id)
    elsif params[:board_id].present?
      post_ids = Post.where(board_id: params[:board_id]).pluck(:id)
      @search_results = @search_results.where(post_id: post_ids)
    end

    if params[:template_id].present?
      @templates = Template.where(id: params[:template_id])
      if @templates.first.present?
        character_ids = Character.where(template_id: @templates.first.id).pluck(:id)
        @search_results = @search_results.where(character_id: character_ids)
      end
    elsif params[:author_id].present?
      @templates = @templates.where(user_id: params[:author_id])
    end

    @search_results = @search_results
      .select('replies.*, characters.name, characters.screenname, users.username, users.deleted as user_deleted')
      .visible_to(current_user)
      .joins(:user)
      .left_outer_joins(:character)
      .paginate(page: page)
      .includes(:post)

    @search_results = @search_results.where.not(post_id: current_user.hidden_posts) if logged_in? && !params[:show_blocked]

    @audits = []

    return if params[:condensed]

    @search_results = @search_results
      .select('icons.keyword, icons.url')
      .left_outer_joins(:icon)
  end
end
