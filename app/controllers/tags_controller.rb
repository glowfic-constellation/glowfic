# frozen_string_literal: true
class TagsController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :find_tag, except: :index
  before_filter :permission_required, except: [:index, :show]

  def index
    @page_title = "Tags"
    @tags = Tag.order('type desc, LOWER(name) asc').paginate(per_page: 25, page: page)
  end

  def show
    @posts = posts_from_relation(@tag.posts)
    @page_title = "#{@tag.name}"
  end

  def edit
    @page_title = "Edit Tag: #{@tag.name}"
  end

  def update
    unless @tag.update_attributes(tag_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "Tag could not be saved because of the following problems:"
      flash.now[:error][:array] = @tag.errors.full_messages
      @page_title = "Edit Tag: #{@tag.name}"
      render action: :edit and return
    end

    flash[:success] = "Tag saved!"
    redirect_to tag_path(@tag)
  end

  def destroy
    @tag.destroy
    flash[:success] = "Tag deleted."
    redirect_to tags_path
  end

  private

  def find_tag
    unless @tag = Tag.find_by_id(params[:id])
      flash[:error] = "Tag could not be found."
      redirect_to tags_path
    end
  end

  def permission_required
    unless @tag.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this tag."
      redirect_to tag_path(@tag)
    end
  end

  def tag_params
    params.fetch(:tag, {}).permit(:name, :type)
  end
end
