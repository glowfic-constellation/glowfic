class Post::Searcher < Generic::Searcher
  def initialize(search=Post.ordered)
    super
  end

  def search(params)
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    @search_results = @search_results.where(id: Setting.find(params[:setting_id]).post_tags.pluck(:post_id)) if params[:setting_id].present?
    if params[:subject].present?
      if params[:abbrev].present?
        search = params[:subject].chars.join('% ')
        @search_results = @search_results.where('subject ILIKE ?', "%#{search}%")
      else
        @search_results = @search_results.search(params[:subject]).where('subject ILIKE ?', "%#{params[:subject]}%")
      end
    end
    @search_results = @search_results.complete if params[:completed].present?
    if params[:author_id].present?
      # get author matches for posts that have at least one
      author_posts = Post::Author.where(user_id: params[:author_id]).group(:post_id)
      # select posts that have all of them
      author_posts = author_posts.having('COUNT(post_authors.user_id) = ?', params[:author_id].length).pluck(:post_id)
      @search_results = @search_results.where(id: author_posts)
    end
    if params[:character_id].present?
      post_ids = Reply.where(character_id: params[:character_id]).select(:post_id).distinct.pluck(:post_id)
      @search_results = @search_results.where(character_id: params[:character_id]).or(@search_results.where(id: post_ids))
    end
  end
end
