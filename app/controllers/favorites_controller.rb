# frozen_string_literal: true
class FavoritesController < ApplicationController
  before_action :login_required

  def index
    @page_title = 'Favorites'

    return if params[:view] == 'bucket'
    unless (@favorites = current_user.favorites).present?
      @posts = []
      return
    end

    user_favorites = @favorites.where(favorite_type: User.to_s).select(:favorite_id)
    author_posts = Post::Author.where(user_id: user_favorites, joined: true).select(:post_id)
    board_favorites = @favorites.where(favorite_type: Board.to_s).select(:favorite_id)
    post_favorites = @favorites.where(favorite_type: Post.to_s).select(:favorite_id)
    character_favorites = @favorites.where(favorite_type: Character.to_s).select(:favorite_id)
    character_posts = Reply.where(character_id: character_favorites).select(:post_id)

    @posts = Post.where(id: author_posts).or(Post.where(id: post_favorites)).or(Post.where(id: character_posts)).or(Post.where(board_id: board_favorites))
    @posts = @posts.not_ignored_by(current_user) if current_user&.hide_from_all
    @posts = posts_from_relation(@posts.ordered, with_unread: true)
    @hide_quicklinks = true
  end

  def create
    favorite = nil

    if params[:user_id].present?
      unless (favorite = User.active.find_by(id: params[:user_id]))
        flash[:error] = "User could not be found."
        redirect_to users_path and return
      end
      fav_path = favorite
    elsif params[:board_id].present?
      unless (favorite = Board.find_by(id: params[:board_id]))
        flash[:error] = "Continuity could not be found."
        redirect_to continuities_path and return
      end
      fav_path = continuity_path(favorite)
    elsif params[:character_id].present?
      unless (favorite = Character.find_by_id(params[:character_id]))
        flash[:error] = "Character could not be found."
        redirect_to characters_path and return
      end
      fav_path = favorite
    elsif params[:post_id].present?
      unless (favorite = Post.find_by(id: params[:post_id]))
        flash[:error] = "Post could not be found."
        redirect_to posts_path and return
      end
      params = {}
      params[:page] = page unless page.to_s == '1'
      params[:per_page] = per_page unless per_page.to_s == (current_user.try(:per_page) || 25).to_s
      fav_path = post_path(favorite, params)
    else
      flash[:error] = "No favorite specified."
      redirect_to continuities_path and return
    end

    fav = Favorite.new
    fav.user = current_user
    fav.favorite = favorite
    begin
      fav.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(fav, action: 'saved', err: e)
    else
      flash[:success] = "Your favorite has been saved."
    end
    redirect_to fav_path
  end

  def destroy
    unless (fav = Favorite.find_by(id: params[:id]))
      flash[:error] = "Favorite could not be found."
      redirect_to favorites_path and return
    end

    unless fav.user_id == current_user.id
      flash[:error] = "You do not have permission to modify this favorite."
      redirect_to favorites_path and return
    end

    begin
      fav.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(fav, action: 'deleted', err: e)
      redirect_to favorites_path
    else
      flash[:success] = "Favorite removed."
      if [User.to_s, Post.to_s].include?(fav.favorite_type)
        redirect_to fav.favorite
      else
        redirect_to continuity_path(fav.favorite)
      end
    end
  end
end
