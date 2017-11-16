# frozen_string_literal: true
class TagsController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :find_tag, except: :index
  before_action :permission_required, except: [:index, :show, :destroy]

  def index

    if params[:view].present?
      unless Tag::TYPES.include?(params[:view])
        flash[:error] = "Invalid filter"
        redirect_to tags_path and return
      end
      @view = params[:view]
      @page_title = @view.titlecase.pluralize
    else
      @page_title = "Tags"
    end

    @tags = Tag.order('type desc, LOWER(name) asc').select('tags.*')
    if @view.present?
      @tags = @tags.where(type: @view)
    else
      @tags = @tags.where.not(type: 'GalleryGroup')
    end
    @tags = @tags.with_item_counts.paginate(per_page: 25, page: page)
  end

  def show
    @posts = posts_from_relation(@tag.posts)
    @characters = @tag.characters.includes(:user, :template)
    @galleries = @tag.galleries.with_icon_count.order('name asc')
    @page_title = @tag.name.to_s
    use_javascript('galleries/expander') if @tag.is_a?(GalleryGroup)
  end

  def edit
    @page_title = "Edit Tag: #{@tag.name}"
    build_editor
  end

  def update
    unless @tag.update_attributes(tag_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "Tag could not be saved because of the following problems:"
      flash.now[:error][:array] = @tag.errors.full_messages
      @page_title = "Edit Tag: #{@tag.name}"
      build_editor
      render action: :edit and return
    end

    flash[:success] = "Tag saved!"
    redirect_to tag_path(@tag)
  end

  def destroy
    unless @tag.deletable_by?(current_user)
      flash[:error] = "You do not have permission to edit this tag."
      redirect_to tag_path(@tag) and return
    end

    @tag.destroy
    flash[:success] = "Tag deleted."

    url_params = {}
    url_params[:page] = page if params[:page].present?
    url_params[:view] = params[:view] if params[:view].present?
    redirect_to tags_path(url_params)
  end

  private

  def find_tag
    unless (@tag = Tag.find_by_id(params[:id]))
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

  def build_editor
    # n.b. this method is unsafe for unpersisted tags (in case we ever add tags#new)
    return unless @tag.is_a?(Setting)
    @parent_settings = @tag.parent_settings.order('tag_tags.id asc') || []
    use_javascript('tags/edit')
  end

  def tag_params
    permitted = [:type, :description, :owned, parent_setting_ids: []]
    permitted.insert(0, :name, :user_id) if current_user.admin? || @tag.user == current_user
    params.fetch(:tag, {}).permit(permitted)
  end
end
