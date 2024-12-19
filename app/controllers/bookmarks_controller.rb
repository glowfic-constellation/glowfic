# frozen_string_literal: true
require 'will_paginate/array'

class BookmarksController < ApplicationController
  before_action :login_required, except: [:search]
  before_action :find_model, only: [:destroy]

  def search
    @page_title = 'Search Bookmarks'
    use_javascript('posts/search')
    use_javascript('bookmarks/rename')
    return unless params[:commit].present?

    @user = User.find_by_id(params[:user_id])
    return unless @user && (@user.id == current_user.try(:id) || @user.public_bookmarks)

    @search_results = @user.bookmarked_replies
    if params[:post_id].present?
      @posts = Post.where(id: params[:post_id])
      @search_results = @search_results.where(post_id: params[:post_id])
    end

    @search_results = @search_results
      .visible_to(current_user)
      .joins(:post)
      .order('posts.subject, replies.created_at, posts.id')
      .joins(:user)
      .left_outer_joins(:character)
      .select('replies.*, user_bookmarks.name as bookmark_name, user_bookmarks.id as bookmark_id, characters.name, ' \
              'characters.screenname, users.username, users.deleted as user_deleted')
      .paginate(page: page)

    @search_results = @search_results.where.not(post_id: current_user.hidden_posts) if logged_in? && !params[:show_blocked]

    @audits = []

    return if params[:condensed]

    @search_results = @search_results
      .left_outer_joins(:icon)
      .select('icons.keyword, icons.url')
  end

  def new
    unless params[:at_id].present?
      flash[:error] = "Reply not selected."
      return redirect_to posts_path
    end

    @reply = Reply.find(params[:at_id])
    unless @reply
      flash[:error] = "Reply not found."
      return redirect_to posts_path
    end

    bookmark = User::Bookmark.where(reply_id: @reply.id, user_id: current_user.id, post_id: @reply.post.id,
      type: 'reply_bookmark',).first_or_initialize
    if bookmark.new_record?
      bookmark.save!
      flash[:success] = "Bookmark added."
    else
      flash[:error] = "Bookmark already exists."
    end

    redirect_back fallback_location: reply_path(@reply, anchor: "reply-#{@reply.id}")
  end

  def destroy
    unless @bookmark.user.id == current_user.try(:id)
      flash[:error] = "You do not have permission to remove this bookmark."
      redirect_back fallback_location: reply_path(@reply, anchor: "reply-#{@reply.id}") and return
    end

    @reply = @bookmark.reply
    begin
      @bookmark.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@bookmark, action: 'deleted', err: e)
    else
      flash[:success] = "Bookmark removed."
    end

    redirect_back fallback_location: reply_path(@reply, anchor: "reply-#{@reply.id}")
  end

  private

  def find_model
    @bookmark = User::Bookmark.find_by_id(params[:id])
    return if @bookmark&.visible_to?(current_user)

    flash[:error] = "Bookmark could not be found."
    redirect_to posts_path and return
  end
end
