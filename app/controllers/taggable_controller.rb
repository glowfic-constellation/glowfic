# frozen_string_literal: true
class TaggableController < ApplicationController
  include CharacterFilter
  include Taggable

  before_action :login_required, except: [:index, :show]
  before_action :readonly_forbidden, except: [:index, :show]
  before_action :find_model, except: :index
  before_action :require_edit_permission, only: [:edit, :update]
  before_action :require_delete_permission, only: [:destroy]

  def index
  end

  def show
    @page_title = @tag.name.to_s
    @view = params[:view]
    @meta_og = og_data

    if @view == 'posts'
      @posts = posts_from_relation(@tag.posts.ordered)
    elsif @view == 'characters'
      @characters = @tag.characters.includes(:user, :template).ordered.paginate(page: page)
      @show_retired = true # page has no buttons for filters, show retired characters by default
    elsif @view == 'galleries'
      @galleries = @tag.galleries.with_icon_count.ordered_by_name
      use_javascript('galleries/expander')
    elsif @view != 'settings'
      @view = 'info'
    end
  end

  def edit
    @page_title = "Edit #{tag_or_setting.titleize}: #{@tag.name}"
    build_editor
  end

  def update
  end

  def destroy
  end

  private

  def require_permission
    return if @tag.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this #{tag_or_setting}."
    redirect_to tag_or_setting_path(@tag)
  end

  def require_delete_permission
    return if @tag.deletable_by?(current_user)
    flash[:error] = "You do not have permission to modify this #{tag_or_setting}."
    redirect_to tag_or_setting_path(@tag)
  end

  def build_editor
    return unless @tag.is_a?(Setting)
    use_javascript('tags/edit')
  end

  def og_data
    desc = []
    desc << generate_short(@tag.description) if @tag.description.present?
    stats = []
    post_count = @tag.posts.privacy_public.count
    stats << ("#{post_count} " + "post".pluralize(post_count)) if post_count > 0
    gallery_count = @tag.galleries.count
    stats << ("#{gallery_count} " + "gallery".pluralize(gallery_count)) if gallery_count > 0
    character_count = @tag.characters.count
    stats << ("#{character_count} " + "character".pluralize(character_count)) if character_count > 0
    desc << stats.join(', ')
    title = [@tag.name]
    title << @tag.user.username if @tag.owned? && !@tag.user.deleted?
    title << (@tag.is_a?(Setting) ? 'Setting' : @tag.type.titleize)
    {
      url: @tag.is_a?(Setting) ? setting_url(@tag) : tag_url(@tag),
      title: title.join(' · '),
      description: desc.join("\n"),
    }
  end

  def permitted_params
    permitted = [:type, :description, :owned]
    permitted.insert(0, :name, :user_id) if current_user.admin? || @tag.user == current_user
    if params.include?(:tag)
      params.fetch(:tag, {}).permit(permitted)
    else
      params.fetch(:setting, {}).permit(permitted)
    end
  end

  def find_model(klass, path)
    unless (@tag = klass.find_by(id: params[:id]))
      flash[:error] = "#{klass.model_name.to_s.titleize} could not be found."
      redirect_to path
    end
  end

  def tag_or_setting
    @tag.is_a?(Setting) ? 'setting' : 'tag'
  end

  def tag_or_setting_path(tag)
    tag.is_a?(Setting) ? setting_path(tag) : tag_path(tag)
  end

  def url_params
    url_params = {}
    url_params[:page] = page if params[:page].present?
    url_params[:view] = params[:view] if params[:view].present?
  end
end
