# frozen_string_literal: true
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
        reply_ids = Reply.where(user_id: favorite_rec.favorite_id).pluck('distinct post_id')
        where_calc = where_calc.where(id: reply_ids)
      elsif favorite_rec.favorite_type == Post.to_s
        where_calc = where_calc.where(id: favorite_rec.favorite_id)
      elsif favorite_rec.favorite_type == Board.to_s
        where_calc = where_calc.where(board_id: favorite_rec.favorite_id)
      end
    end

    @posts = posts_from_relation(@posts.where(where_calc.where_values.reduce(:or)).order('tagged_at desc'))
    @hide_quicklinks = true
    @page_title = 'Favorites'
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
      params = {}
      params[:page] = page unless page.to_s == '1'
      params[:per_page] = per_page unless per_page.to_s == (current_user.try(:per_page) || 25).to_s
      fav_path = post_path(favorite, params)
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
