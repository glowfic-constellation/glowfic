# frozen_string_literal: true
class TemplatesController < ApplicationController
  include CharacterFilter

  before_action :login_required, except: [:show, :search]
  before_action :find_model, only: [:show, :destroy, :edit, :update]
  before_action :require_create_permission, only: [:new, :create]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]
  before_action :editor_setup, only: [:new, :edit]

  def new
    @template = Template.new
    @page_title = "New Template"
  end

  def create
    @template = Template.new(permitted_params)
    @template.user = current_user
    begin
      @template.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@template, action: 'created', now: true, err: e)

      editor_setup
      @page_title = "New Template"
      render :new
    else
      flash[:success] = "Template created."
      redirect_to @template
    end
  end

  def show
    @user = @template.user
    character_ids = @template.characters.pluck(:id)
    post_ids = Reply.where(character_id: character_ids).select(:post_id).distinct.pluck(:post_id)
    posts = Post.where(character_id: character_ids).or(Post.where(id: post_ids))
    @posts = posts_from_relation(posts.ordered)
    @page_title = @template.name
    @meta_og = og_data
  end

  def edit
    @page_title = 'Edit Template: ' + @template.name
  end

  def update
    begin
      @template.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@template, action: 'updated', now: true, err: e)

      editor_setup
      @page_title = 'Edit Template: ' + @template.name_was
      render :edit
    else
      flash[:success] = "Template updated."
      redirect_to @template
    end
  end

  def destroy
    begin
      @template.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@template, action: 'deleted', err: e)
      redirect_to @template
    else
      flash[:success] = "Template deleted."
      redirect_to user_characters_path(current_user)
    end
  end

  def search
  end

  private

  def editor_setup
    @selectable_characters = @template.try(:characters) || []
    @selectable_characters += current_user.characters.where(template_id: nil).ordered
    @selectable_characters.uniq!
    @character_ids = permitted_params[:character_ids] if permitted_params.key?(:character_ids)
    @character_ids ||= @template.try(:character_ids) || []
  end

  def find_model
    return if (@template = Template.find_by_id(params[:id]))
    flash[:error] = "Template could not be found."
    if logged_in?
      redirect_to user_characters_path(current_user)
    else
      redirect_to root_path
    end
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create templates."
    redirect_to continuities_path and return
  end

  def require_edit_permission
    return true if @template.user_id == current_user.id
    flash[:error] = "You do not have permission to modify this template."
    redirect_to user_characters_path(current_user)
  end

  def og_data
    desc = []
    character_count = @template.characters.count
    desc << generate_short(@template.description) if @template.description.present?
    desc << "#{character_count} #{'character'.pluralize(character_count)}"
    title = [@template.name]
    title.prepend(@template.user.username) unless @template.user.deleted?
    {
      url: template_url(@template),
      title: title.join(' » '),
      description: desc.join("\n"),
    }
  end

  def permitted_params
    params.fetch(:template, {}).permit(:name, :description, character_ids: [])
  end
end
