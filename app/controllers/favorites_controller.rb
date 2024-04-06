# frozen_string_literal: true
class FavoritesController < ApplicationController
  before_action :login_required

  def index
    @page_title = t('.title')

    return if params[:view] == 'bucket'
    unless (@favorites = current_user.favorites).present?
      @posts = []
      return
    end

    user_favorites = @favorites.where(favorite_type: User.to_s).select(:favorite_id)
    author_posts = Post::Author.where(user_id: user_favorites, joined: true).select(:post_id)
    board_favorites = @favorites.where(favorite_type: Board.to_s).select(:favorite_id)
    post_favorites = @favorites.where(favorite_type: Post.to_s).select(:favorite_id)

    @posts = Post.where(id: author_posts).or(Post.where(id: post_favorites)).or(Post.where(board_id: board_favorites))
    @posts = posts_from_relation(@posts.ordered, with_unread: true)
    @hide_quicklinks = true
  end

  def create
    favorite = nil

    if params[:user_id].present?
      unless (favorite = User.active.find_by_id(params[:user_id]))
        flash[:error] = t('users.errors.not_found')
        redirect_to users_path and return
      end
      fav_path = favorite
    elsif params[:board_id].present?
      unless (favorite = Board.find_by_id(params[:board_id]))
        flash[:error] = t('boards.errors.not_found')
        redirect_to continuities_path and return
      end
      fav_path = continuity_path(favorite)
    elsif params[:post_id].present?
      unless (favorite = Post.find_by_id(params[:post_id]))
        flash[:error] = t('posts.errors.not_found')
        redirect_to posts_path and return
      end
      params = {}
      params[:page] = page unless page.to_s == '1'
      params[:per_page] = per_page unless per_page.to_s == (current_user.try(:per_page) || 25).to_s
      fav_path = post_path(favorite, params)
    else
      flash[:error] = t('favorites.errors.not_specified')
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
      flash[:success] = t('.success')
    end
    redirect_to fav_path
  end

  def destroy
    unless (fav = Favorite.find_by_id(params[:id]))
      flash[:error] = t('favorites.errors.not_found')
      redirect_to favorites_path and return
    end

    unless fav.user_id == current_user.id
      flash[:error] = t('favorites.errors.no_permission.edit')
      redirect_to favorites_path and return
    end

    begin
      fav.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(fav, action: 'deleted', err: e)
      redirect_to favorites_path
    else
      flash[:success] = t('.success')
      if [User.to_s, Post.to_s].include?(fav.favorite_type)
        redirect_to fav.favorite
      else
        redirect_to continuity_path(fav.favorite)
      end
    end
  end
end
