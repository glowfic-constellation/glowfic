# frozen_string_literal: true
require 'will_paginate/array'

class BookmarksController < ApplicationController
  before_action :login_required, except: :search
  before_action :bookmark_ownership_required, only: :destroy

  def search
    @page_title = 'Search Bookmarks'
    use_javascript('search')
    use_javascript('bookmarks/rename')
    return unless params[:commit].present?
    return unless (@user = User.find_by(id: params[:user_id]))

    response.headers['X-Robots-Tag'] = 'noindex'
    @search_results = @user.bookmarked_replies.bookmark_visible_to(@user, current_user)
    if @search_results.empty?
      # Return empty list when a user's bookmarks are private
      @search_results = @search_results.paginate(page: 1)
      return
    end

    if params[:post_id].present?
      @posts = Post.where(id: params[:post_id])
      @search_results = @search_results.where(post_id: params[:post_id])
    end

    @search_results = @search_results
      .joins(:post)
      .order('posts.subject, replies.created_at, posts.id')
      .joins(:user)
      .left_outer_joins(:character)
      .select('replies.*, bookmarks.id as bookmark_id, bookmarks.name as bookmark_name, bookmarks.public as bookmark_public, characters.name, ' \
              'characters.screenname, users.username, users.deleted as user_deleted')
      .paginate(page: page)

    @search_results = @search_results.where.not(post_id: current_user.hidden_posts) if logged_in? && !params[:show_blocked]

    @audits = []
    calculate_reply_bookmarks(@search_results)
  end

  def create
    unless params[:at_id].present?
      flash[:error] = "Reply not selected."
      return redirect_to posts_path
    end

    @reply = Reply.find_by(id: params[:at_id])
    unless @reply
      flash[:error] = "Reply not found."
      return redirect_to posts_path
    end

    bookmark = Bookmark.where(reply_id: @reply.id, user_id: current_user.id, type: 'reply_bookmark').first_or_initialize
    if bookmark.new_record?
      bookmark.update!(params.permit(:name, :public).merge(post_id: @reply.post_id))
      flash[:success] = "Bookmark added."
    else
      flash[:error] = "Bookmark already exists."
    end

    redirect_to "#{request.referer || reply_path(@reply)}#reply-#{@reply.id}"
  end

  def destroy
    begin
      @bookmark.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@bookmark, action: 'deleted', err: e)
    else
      flash[:success] = "Bookmark removed."
    end

    redirect_to "#{request.referer || reply_path(@reply)}#reply-#{@reply.id}"
  end

  private

  def bookmark_ownership_required
    @bookmark = Bookmark.find_by(id: params[:id])
    unless @bookmark&.visible_to?(current_user)
      flash[:error] = "Bookmark could not be found."
      redirect_to posts_path and return
    end

    @reply = @bookmark.reply
    return if @bookmark.user.id == current_user.try(:id)

    flash[:error] = "You do not have permission to perform this action."
    redirect_to "#{request.referer || reply_path(@reply)}#reply-#{@reply.id}"
  end
end
