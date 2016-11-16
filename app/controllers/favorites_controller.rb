class FavoritesController < ApplicationController
  before_filter :login_required

  def index
    unless current_user.favorites.present?
      @posts = []
      return
    end

    @posts = Post.unscoped
    where_calc = Post.unscoped

    current_user.favorites.each do |favorite_rec|
      if favorite_rec.favorite_type == User.to_s
        where_calc = where_calc.where(user_id: favorite_rec.favorite_id)
        reply_ids = Reply.where(user_id: favorite_rec.favorite_id).select(:post_id).group(:post_id).map(&:post_id)
        where_calc = where_calc.where(id: reply_ids)
      elsif favorite_rec.favorite_type == Post.to_s
        where_calc = where_calc.where(id: favorite_rec.favorite_id)
      elsif favorite_rec.favorite_type == Board.to_s
        where_calc = where_calc.where(board_id: favorite_rec.favorite_id)
      end
    end

    @posts = @posts.where(where_calc.where_values.reduce(:or))
    @posts = @posts.includes(:board, :user, :last_user, :content_warnings)
    @posts = @posts.order('tagged_at desc')
    @posts = @posts.paginate(per_page: 25, page: page)
    opened_posts = PostView.where(user_id: current_user.id).select([:post_id, :read_at])
    @opened_ids = opened_posts.map(&:post_id)
    @unread_ids = opened_posts.select do |view|
      post = @posts.detect { |p| p.id == view.post_id }
      post && view.read_at < post.tagged_at
    end.map(&:post_id)
    @page_title = "Favorites"
  end

  def create
    favorite = nil

    if params[:user_id].present?
      unless favorite = User.find_by_id(params[:user_id])
        flash[:error] = "User could not be found."
        redirect_to users_path and return
      end
      fav_path = user_path(favorite)
    elsif params[:board_id].present?
      unless favorite = Board.find_by_id(params[:board_id])
        flash[:error] = "Continuity could not be found."
        redirect_to boards_path and return
      end
      fav_path = board_path(favorite)
    elsif params[:post_id].present?
      unless favorite = Post.find_by_id(params[:post_id])
        flash[:error] = "Post could not be found."
        redirect_to posts_path and return
      end
      fav_path = session[:previous_url] || post_path(favorite)
    else
      flash[:error] = "No favorite specified."
      redirect_to boards_path and return
    end

    fav = Favorite.new
    fav.user = current_user
    fav.favorite = favorite
    if fav.save
      flash[:success] = "Your favorite has been saved."
    else
      flash[:error] = {}
      flash[:error][:message] = "Your favorite could not be saved because of the following problems:"
      flash[:error][:array] = fav.errors.full_messages
    end
    redirect_to fav_path
  end

  def destroy
    unless fav = Favorite.find_by_id(params[:id])
      flash[:error] = "Favorite could not be found."
      redirect_to favorites_path and return
    end

    unless fav.user_id == current_user.id
      flash[:error] = "That is not your favorite."
      redirect_to favorites_path and return
    end

    fav.destroy
    flash[:success] = "Favorite removed."
    if fav.favorite_type == User.to_s
      redirect_to user_path(fav.favorite)
    elsif fav.favorite_type == Post.to_s
      redirect_to post_path(fav.favorite)
    else
      redirect_to board_path(fav.favorite)
    end
  end
end
