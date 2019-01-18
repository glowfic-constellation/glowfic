# frozen_string_literal: true
class TagsController < ApplicationController
  include Taggable

  before_action :login_required, except: [:index, :show]
  before_action :find_tag, except: :index
  before_action :permission_required, except: [:index, :show, :destroy]

  def index
    @tags = TagSearcher.new.search(tag_name: params[:name], tag_type: params[:view], page: page)
    @view = params[:view]
    @page_title = @view.present? ? @view.titlecase.pluralize : 'Tags'
    @tag_options = (Tag::TYPES - ['GalleryGroup']).sort.reverse.map{|t| [t.titlecase, t]}.to_h
    use_javascript('tags/index')
  rescue InvalidTagType => e
    flash[:error] = e.api_error
    redirect_to tags_path
  end

  def show
    @page_title = @tag.name.to_s
    @view = params[:view]

    if @view == 'posts'
      @posts = posts_from_relation(@tag.posts)
    elsif @view == 'characters'
      @characters = @tag.characters.includes(:user, :template).ordered.paginate(per_page: 25, page: page)
    elsif @view == 'galleries'
      @galleries = @tag.galleries.with_icon_count.ordered_by_name
      use_javascript('galleries/expander')
    elsif @view != 'settings'
      @view = 'info'
    end
  end

  def edit
    @page_title = "Edit Tag: #{@tag.name}"
    build_editor
  end

  def update
    @tag.assign_attributes(tag_params)

    begin
      Tag.transaction do
        @tag.parent_settings = process_tags(Setting, :tag, :parent_setting_ids) if @tag.is_a?(Setting)
        @tag.save!
      end
      flash[:success] = "Tag saved!"
      redirect_to tag_path(@tag)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {}
      flash.now[:error][:message] = "Tag could not be saved because of the following problems:"
      flash.now[:error][:array] = @tag.errors.full_messages
      @page_title = "Edit Tag: #{@tag.name}"
      build_editor
      render :edit and return
    end
  end

  def destroy
    unless @tag.deletable_by?(current_user)
      flash[:error] = "You do not have permission to edit this tag."
      redirect_to tag_path(@tag) and return
    end

    begin
      @tag.destroy!
      flash[:success] = "Tag deleted."

      url_params = {}
      url_params[:page] = page if params[:page].present?
      url_params[:view] = params[:view] if params[:view].present?
      redirect_to tags_path(url_params)
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {}
      flash[:error][:message] = "Tag could not be deleted."
      flash[:error][:array] = @tag.errors.full_messages
      redirect_to tag_path(@tag)
    end
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
    return unless @tag.is_a?(Setting)
    use_javascript('tags/edit')
  end

  def tag_params
    permitted = [:type, :description, :owned]
    permitted.insert(0, :name, :user_id) if current_user.admin? || @tag.user == current_user
    params.fetch(:tag, {}).permit(permitted)
  end
end
