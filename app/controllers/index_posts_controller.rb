# frozen_string_literal: true
class IndexPostsController < ApplicationController
  before_action :login_required
  before_action :readonly_forbidden
  before_action :find_model, only: [:edit, :update, :destroy]

  def new
    unless (index = Index.find_by_id(params[:index_id]))
      flash[:error] = t('indexes.errors.not_found')
      redirect_to indexes_path and return
    end

    unless index.editable_by?(current_user)
      flash[:error] = t('indexes.errors.no_permission.edit')
      redirect_to index_path(index) and return
    end

    @index_post = IndexPost.new(index: index, index_section_id: params[:index_section_id])
    @page_title = t('.title')
    use_javascript('posts/index_post_new')
  end

  def create
    @index_post = IndexPost.new(permitted_params)

    # populate index if appropriate:
    @index_post.validate

    if @index_post.index && !@index_post.index.editable_by?(current_user)
      flash[:error] = t('indexes.errors.no_permission.edit') # rubocop:disable Rails/ActionControllerFlashBeforeRender
      redirect_to @index_post.index and return
    end

    unless @index_post.save
      render_errors(@index_post, now: true, action: 'added', msg: t('.failure'))
      @page_title = t('index_posts.new.title')
      use_javascript('posts/index_post_new')
      render :new and return
    end

    flash[:success] = t('.success')
    redirect_to @index_post.index
  end

  def edit
    @page_title = t('.title')
  end

  def update
    unless @index_post.update(permitted_params)
      render_errors(@index_post, action: 'updated', now: true, class_name: 'Index')
      @page_title = t('index_posts.edit.title')
      render action: :edit and return
    end

    flash[:success] = t('.success')
    redirect_to @index_post.index
  end

  def destroy
    begin
      @index_post.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@index_post, action: 'removed', msg: t('.failure'), err: e)
    else
      flash[:success] = t('.success')
    end
    redirect_to @index_post.index
  end

  private

  def permitted_params
    params.fetch(:index_post, {}).permit(:description, :index_id, :index_section_id, :post_id)
  end

  def find_model
    unless (@index_post = IndexPost.find_by_id(params[:id]))
      flash[:error] = t('index_posts.errors.not_found')
      redirect_to indexes_path and return
    end

    return if @index_post.index.editable_by?(current_user)
    flash[:error] = t('indexes.errors.no_permission.edit')
    redirect_to @index_post.index
  end
end
