# frozen_string_literal: true
class TagsController < ApplicationController
  include CharacterFilter
  include Taggable

  before_action :login_required, except: [:index, :show]
  before_action :readonly_forbidden, except: [:index, :show]
  before_action :find_model, except: :index
  before_action :require_permission, except: [:index, :show, :destroy]

  def index
    @tags = TagSearcher.new.search(tag_name: params[:name], tag_type: params[:view], page: page)
    @post_counts = Post.visible_to(current_user).joins(post_tags: :tag).where(post_tags: { tag_id: @tags.map(&:id) })
    @post_counts = @post_counts.group('post_tags.tag_id').count
    @view = params[:view]
    @page_title = @view.present? ? @view.titlecase.pluralize : 'Tags'
    @tag_options = (Tag::TYPES - ['GalleryGroup']).sort.reverse.index_by(&:titlecase)
    use_javascript('tags/index')
  rescue InvalidTagType => e
    flash[:error] = e.api_error
    redirect_to tags_path
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
    @page_title = "Edit Tag: #{@tag.name}"
    build_editor
  end

  def update
    @tag.assign_attributes(permitted_params)

    begin
      Tag.transaction do
        @tag.parent_settings = process_tags(Setting, obj_param: :tag, id_param: :parent_setting_ids) if @tag.is_a?(Setting)
        @tag.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@tag, action: 'updated', now: true, err: e)

      @page_title = "Edit Tag: #{@tag.name}"
      build_editor
      render :edit
    else
      flash[:success] = "Tag updated."
      redirect_to tag_path(@tag)
    end
  end

  def destroy
    unless @tag.deletable_by?(current_user)
      flash[:error] = "You do not have permission to modify this tag."
      redirect_to tag_path(@tag) and return
    end

    begin
      @tag.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@tag, action: 'deleted', err: e)
      redirect_to tag_path(@tag)
    else
      flash[:success] = "Tag deleted."

      url_params = {}
      url_params[:page] = page if params[:page].present?
      url_params[:view] = params[:view] if params[:view].present?
      redirect_to tags_path(url_params)
    end
  end

  def search
    @page_title = 'Search Tags'
    use_javascript('tags/search')
    @tag_options = (Tag::TYPES - ['GalleryGroup']).sort.reverse.index_by(&:titlecase)
    @users = User.active.where(id: params[:author_id]) if params[:author_id].present?
    return unless params[:commit].present?

    @tags = TagSearcher.new.search(tag_name: params[:name], tag_type: params[:view], user_id: params[:author_id], page: page)
    @post_counts = Post.visible_to(current_user).joins(post_tags: :tag).where(post_tags: { tag_id: @tags.map(&:id) })
    @post_counts = @post_counts.group('post_tags.tag_id').count
  rescue InvalidTagType => e
    flash[:error] = e.api_error
    redirect_to tags_path
  end

  private

  def find_model
    return if (@tag = Tag.find_by(id: params[:id]))
    flash[:error] = "Tag could not be found."
    redirect_to tags_path
  end

  def require_permission
    return if @tag.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this tag."
    redirect_to tag_path(@tag)
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
    title << @tag.type.titleize
    {
      url: tag_url(@tag),
      title: title.join(' · '),
      description: desc.join("\n"),
    }
  end

  def permitted_params
    permitted = [:type, :description, :owned]
    permitted.insert(0, :name, :user_id) if current_user.admin? || @tag.user == current_user
    params.fetch(:tag, {}).permit(permitted)
  end
end
