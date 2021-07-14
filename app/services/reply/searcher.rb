class Reply::Searcher < Generic::Service
  attr_reader :templates

  def initialize(post: nil, templates: [])
    @post = post
    @templates = templates
    @search_results = Reply.unscoped
    super()
  end

  def search(params, user)
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where(character_id: params[:character_id]) if params[:character_id].present?
    @search_results = @search_results.where(icon_id: params[:icon_id]) if params[:icon_id].present?
    search_content(params[:subj_content]) if params[:subj_content].present?
    sort(params[:sort], params[:subj_content])
    filter_posts(params[:board_id])
    filter_templates(params[:template_id], params[:author_id])

    @search_results = @search_results
      .select('replies.*, characters.name, characters.screenname, users.username, users.deleted as user_deleted')
      .visible_to(user)
      .joins(:user)
      .left_outer_joins(:character)
      .includes(:post)

    @search_results = @search_results.where.not(post_id: user.hidden_posts) if user.present? && !params[:show_blocked]

    unless params[:condensed]
      @search_results = @search_results
        .select('icons.keyword, icons.url')
        .left_outer_joins(:icon)
    end
  end

  private

  def search_content(content)
    @search_results = @search_results.search(content).with_pg_search_highlight
    exact_phrases = content.scan(/"([^"]*)"/)
    if exact_phrases.present?
      exact_phrases.each do |phrase|
        phrase = phrase.first.strip
        next if phrase.blank?
        @search_results = @search_results.where("replies.content LIKE ?", "%#{phrase}%")
      end
    end
  end

  def sort(sort, content)
    append_rank = content.present? ? ', rank DESC' : ''
    if ['created_new', 'created_old'].include?(sort)
      order = case sort
        when 'created_new'
          'replies.created_at DESC'
        when 'created_old'
          'replies.created_at ASC'
      end
      @search_results = @search_results.except(:order).order(order + append_rank)
    elsif content.blank?
      @search_results = @search_results.order('replies.created_at DESC')
    end
  end

  def filter_posts(board_id)
    if @post
      @search_results = @search_results.where(post_id: @post.id)
    elsif board_id.present?
      post_ids = Post.where(board_id: board_id).pluck(:id)
      @search_results = @search_results.where(post_id: post_ids)
    end
  end

  def filter_templates(template_id, author_id)
    if template_id.present?
      if (template = Template.find_by(id: template_id))
        character_ids = Character.where(template_id: template.id).pluck(:id)
        @search_results = @search_results.where(character_id: character_ids)
        @templates = [template]
      end
    elsif author_id.present?
      @templates = @templates.where(user_id: author_id)
    end
  end
end
