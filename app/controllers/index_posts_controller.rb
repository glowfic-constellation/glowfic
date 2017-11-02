# frozen_string_literal: true
class IndexPostsController < ApplicationController
  before_action :login_required

  def new
    unless (index = Index.find_by_id(params[:index_id]))
      flash[:error] = "Index could not be found."
      redirect_to indexes_path and return
    end

    unless index.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this index."
      redirect_to index_path(index) and return
    end

    @index_post = IndexPost.new(index: index, index_section_id: params[:index_section_id])
    @page_title = "Add Posts to Index"
    use_javascript('posts/index_post_new')
  end

  def create
    @index_post = IndexPost.new(index_params)

    if @index_post.index && !@index_post.index.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this index."
      redirect_to index_path(@index_post.index) and return
    end

    if @index_post.save
      flash[:success] = "Post added to index!"
      redirect_to index_path(@index_post.index) and return
    end

    flash.now[:error] = {}
    flash.now[:error][:message] = "Post could not be added to index."
    flash.now[:error][:array] = @index_post.errors.full_messages
    @page_title = 'Add Posts to Index'
    use_javascript('posts/index_post_new')
    render :action => :new
  end

  def destroy
    unless (index_post = IndexPost.find_by_id(params[:id]))
      flash[:error] = "Index post could not be found."
      redirect_to indexes_path and return
    end

    unless index_post.index.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this index."
      redirect_to index_path(index_post.index) and return
    end

    index_post.destroy
    flash[:success] = "Post removed from index."
    redirect_to index_path(index_post.index)
  end

  private

  def index_params
    params.fetch(:index_post, {}).permit(:description, :index_id, :index_section_id, :post_id)
  end
end
