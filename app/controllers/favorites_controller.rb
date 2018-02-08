# frozen_string_literal: true
class FavoritesController < ApplicationController
  before_action :login_required

  def index
    return if params[:view] == 'bucket'
    unless current_user.favorites.present?
      @posts = []
      return
    end

    @posts = Post.unscoped
    arel = Post.arel_table
    where_calc = nil

    current_user.favorites.each do |favorite_rec|
      new_calc = nil
      if favorite_rec.favorite_type == User.to_s
        post_ids = PostAuthor.where(user_id: favorite_rec.favorite_id).where(joined: true).pluck(:post_id)
        new_calc = arel[:id].in(post_ids)
      elsif favorite_rec.favorite_type == Post.to_s
        new_calc = arel[:id].eq(favorite_rec.favorite_id)
      elsif favorite_rec.favorite_type == Board.to_s
        new_calc = arel[:board_id].eq(favorite_rec.favorite_id)
      end
      if where_calc.nil?
        where_calc = new_calc
      else
        where_calc = where_calc.or(new_calc)
      end
    end

    @posts = posts_from_relation(@posts.where(where_calc).order('tagged_at desc'))
    @hide_quicklinks = true
    @page_title = 'Favorites'
  end

  def create
    favorite = nil

    if params[:user_id].present?
      unless (favorite = User.find_by_id(params[:user_id]))
        flash[:error] = "User could not be found."
        redirect_to users_path and return
      end
      fav_path = user_path(favorite)
    elsif params[:board_id].present?
      unless (favorite = Board.find_by_id(params[:board_id]))
        flash[:error] = "Continuity could not be found."
        redirect_to boards_path and return
      end
      fav_path = board_path(favorite)
    elsif params[:post_id].present?
      unless (favorite = Post.find_by_id(params[:post_id]))
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
    unless (fav = Favorite.find_by_id(params[:id]))
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
