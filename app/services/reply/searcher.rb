# frozen_string_literal: true
class Reply::Searcher < Generic::Searcher
  attr_reader :users, :characters, :templates, :boards

  def initialize(search=Reply.unscoped, current_user: nil, post: nil)
    @current_user = current_user
    @post = post
    super(search)
  end

  def setup(params)
    if @post&.visible_to?(@current_user)
      @users = @post.authors.active
      char_ids = @post.replies.select(:character_id).distinct.pluck(:character_id) + [@post.character_id]
      @characters = Character.where(id: char_ids).ordered
      @templates = Template.where(id: @characters.map(&:template_id).uniq.compact).ordered
    elsif @post.nil?
      @users = User.active.full.where(id: params[:author_id]) if params[:author_id].present?
      @characters = Character.where(id: params[:character_id]) if params[:character_id].present?
      @templates = Template.ordered.limit(25)
      @boards = Board.where(id: params[:board_id]) if params[:board_id].present?
    end
  end

  def search(params, page: 1)
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where(character_id: params[:character_id]) if params[:character_id].present?
    @search_results = @search_results.where(icon_id: params[:icon_id]) if params[:icon_id].present?

    search_content(params[:subj_content]) if params[:subj_content].present?
    sort_results(params[:sort], params[:subject_content].present?)
    filter_parents(params[:board_id])
    filter_characters(params[:template_id], params[:author_id])
    construct_query(params, page)

    @search_results
  end

  private

  def search_content(search)
    @search_results = @search_results.search(search).with_pg_search_highlight
    exact_phrases = search.scan(/"([^"]*)"/)
    return unless exact_phrases.present?
    exact_phrases.each do |phrase|
      phrase = phrase.first.strip
      next if phrase.blank?
      @search_results = @search_results.where("replies.content ILIKE ?", "%#{phrase}%")
    end
  end

  def sort_results(sort, content_search)
    append_rank = content_search ? ', rank DESC' : ''
    if sort == 'created_new'
      @search_results = @search_results.except(:order).order('replies.created_at DESC' + append_rank)
    elsif sort == 'created_old'
      @search_results = @search_results.except(:order).order('replies.created_at ASC' + append_rank)
    elsif !content_search
      @search_results = @search_results.order('replies.created_at DESC')
    end
  end

  def filter_parents(board_id)
    if @post
      @search_results = @search_results.where(post_id: @post.id)
    elsif board_id.present?
      post_ids = Post.where(board_id: board_id).pluck(:id)
      @search_results = @search_results.where(post_id: post_ids)
    end
  end

  def filter_characters(template_id, user_id)
    if template_id.present?
      @templates = Template.where(id: template_id)
      if @templates.first.present?
        character_ids = Character.where(template_id: @templates.first.id).pluck(:id)
        @search_results = @search_results.where(character_id: character_ids)
      end
    elsif user_id.present?
      @templates = @templates.where(user_id: user_id)
    end
  end

  def construct_query(params, page)
    @search_results = @search_results
      .select('replies.*, characters.name, characters.screenname, users.username, users.deleted as user_deleted')
      .visible_to(@current_user)
      .joins(:user)
      .left_outer_joins(:character)
      .includes(:post)

    @search_results = @search_results.where.not(post_id: @current_user.hidden_posts) unless @current_user.nil? || params[:show_blocked]

    @search_results = @search_results.paginate(page: page)

    return if params[:condensed]

    @search_results = @search_results
      .select('icons.keyword, icons.url')
      .left_outer_joins(:icon)
  end
end
