# frozen_string_literal: true
class TagsController < ApplicationController
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
    @meta_og = og_data

    if @view == 'posts'
      @posts = posts_from_relation(@tag.posts.ordered)
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
        assign_owners
        assign_children
        @tag.save!
      end
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Tag could not be saved because of the following problems:",
        array: @tag.errors.full_messages
      }
      @page_title = "Edit Tag: #{@tag.name}"
      build_editor
      render :edit
    else
      flash[:success] = "Tag saved!"
      redirect_to tag_path(@tag)
    end
  end

  def destroy
    unless @tag.deletable_by?(current_user)
      flash[:error] = "You do not have permission to edit this tag."
      redirect_to tag_path(@tag) and return
    end

    begin
      @tag.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Tag could not be deleted.",
        array: @tag.errors.full_messages
      }
      redirect_to tag_path(@tag)
    else
      flash[:success] = "Tag deleted."

      url_params = {}
      url_params[:page] = page if params[:page].present?
      url_params[:view] = params[:view] if params[:view].present?
      redirect_to tags_path(url_params)
    end
  end

  private

  def find_tag
    unless (@tag = Tag.find_by(id: params[:id]))
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

  def og_data
    desc = []
    desc << generate_short(@tag.description) if @tag.description.present?
    stats = []
    post_count = @tag.posts.where(privacy: Concealable::PUBLIC).count
    stats << "#{post_count} " + "post".pluralize(post_count) if post_count > 0
    if @tag.is_a?(GalleryGroup)
      gallery_count = @tag.galleries.count
      stats << "#{gallery_count} " + "gallery".pluralize(gallery_count) if gallery_count > 0
    end
    character_count = @tag.characters.count
    stats << "#{character_count} " + "character".pluralize(character_count) if character_count > 0
    desc << stats.join(', ')
    title = [@tag.name]
    title << @tag.owners.map(&:username).join(', ') if @tag.owners.exists?
    title << @tag.class.to_s.titleize
    {
      url: tag_url(@tag),
      title: title.join(' · '),
      description: desc.join("\n"),
    }
  end

  def assign_owners
    owner_ids = params.fetch(:tag, {})[:owner_ids]
    return unless owner_ids.present?
    owner_ids -= @tag.owner_ids
    owner_ids.each { |owner_id| ActsAsTaggableOn::Tagging.create(taggable_type: 'User', taggable_id: owner_id, tag: @tag, context: 'settings') }
  end

  def assign_children
    children_ids = params.fetch(:tag, {})[:children_ids]
    return unless children_ids.present?
    children_ids -= @tag.children_ids
    children_ids.each do |owner_id|
      ActsAsTaggableOn::Tagging.create(taggable_type: 'ActsAsTaggableOn::Tag', taggable_id: owner_id, tag: @tag, context: 'settings')
    end
  end

  def tag_params
    permitted = [:type, :description, :owned]
    if current_user.admin? || @tag.owners.include?(current_user)
      permitted << :name
      permitted << {setting_list: []} if @tag.is_a?(Setting)
    end
    params.fetch(:tag, {}).permit(permitted)
  end
end
