# frozen_string_literal: true
class IndexPostsController < ApplicationController
  before_action :login_required
  before_action :readonly_forbidden
  before_action :find_model, only: [:edit, :update, :destroy]
  before_action :find_index, only: [:new, :create]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]
  before_action :require_create_permission, only: [:new, :create]

  def new
    @index_post = IndexPost.new(index: @index, index_section_id: params[:index_section_id])
    @page_title = "Add Posts to Index"
    use_javascript('posts/index_post_new')
  end

  def create
    @index_post = IndexPost.new(permitted_params)

    # populate index if appropriate:
    @index_post.validate

    unless @index_post.save
      render_errors(@index_post, now: true, action: 'added', msg: 'Post could not be added to index')
      @page_title = 'Add Posts to Index'
      use_javascript('posts/index_post_new')
      render :new and return
    end

    flash[:success] = "Post added to index."
    redirect_to @index_post.index
  end

  def edit
    @page_title = "Edit Post in Index"
  end

  def update
    unless @index_post.update(permitted_params)
      render_errors(@index_post, action: 'updated', now: true, class_name: 'Index')
      @page_title = "Edit Post in Index"
      render action: :edit and return
    end

    flash[:success] = "Index post updated."
    redirect_to @index_post.index
  end

  def destroy
    begin
      @index_post.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@index_post, action: 'removed', msg: 'Post could not be removed from index', err: e)
    else
      flash[:success] = "Post removed from index."
    end
    redirect_to @index_post.index
  end

  private

  def permitted_params
    params.fetch(:index_post, {}).permit(:description, :index_id, :index_section_id, :post_id)
  end

  def find_model
    return if (@index_post = IndexPost.find_by(id: params[:id]))
    flash[:error] = "Index post could not be found."
    redirect_to indexes_path
  end

  def find_index
    id = params[:index_id] || permitted_params[:index_id]
    return if (@index = Index.find_by(id: id))
    flash[:error] = "Index could not be found."
    redirect_to indexes_path
  end

  def require_create_permission
    return if @index.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this index."
    redirect_to @index
  end

  def require_edit_permission
    return if @index_post.index.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this index."
    redirect_to @index_post.index
  end
end
