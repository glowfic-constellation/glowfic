# frozen_string_literal: true
class IndexesController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :find_model, except: [:index, :new, :create]
  before_action :require_create_permission, only: [:new, :create]
  before_action :require_edit_permission, except: [:index, :new, :create, :show]
  before_action :editor_setup, only: :edit

  def index
    @page_title = "Indexes"
    @indexes = Index.order('id asc').paginate(page: page)
  end

  def new
    @page_title = "New Index"
    @index = Index.new(user: current_user)
  end

  def create
    @index = Index.new(permitted_params)
    @index.user = current_user

    begin
      @index.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@index, action: 'created', now: true, err: e)

      @page_title = 'New Index'
      render :new
    else
      flash[:success] = "Index created."
      redirect_to @index and return
    end
  end

  def show
    unless @index.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this index."
      redirect_to indexes_path and return
    end

    @page_title = @index.name.to_s
    @sectionless = @index.posts.where(index_posts: { index_section_id: nil })
    @sectionless = @sectionless.ordered_by_index
    dbselect = ', index_posts.description as index_description, index_posts.id as index_post_id'
    @sectionless = posts_from_relation(@sectionless, with_pagination: false, select: dbselect)
  end

  def edit
  end

  def update
    begin
      @index.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@index, action: 'updated', now: true, err: e)
      editor_setup
      render :edit
    else
      flash[:success] = "Index updated."
      redirect_to @index
    end
  end

  def destroy
    begin
      @index.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@index, action: 'deleted', err: e)
      redirect_to @index
    else
      redirect_to indexes_path
      flash[:success] = "Index deleted."
    end
  end

  private

  def find_model
    return if (@index = Index.find_by(id: params[:id]))
    flash[:error] = "Index could not be found."
    redirect_to indexes_path
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create indexes."
    redirect_to continuities_path and return
  end

  def require_edit_permission
    return if @index.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this index."
    redirect_to @index
  end

  def permitted_params
    params.fetch(:index, {}).permit(:name, :description, :privacy, :authors_locked)
  end

  def editor_setup
    @page_title = "Edit Index: #{@index.name}"
    use_javascript('posts/index_edit')
    @index_sections = @index.index_sections.ordered
    @unsectioned_posts = @index.posts.where(index_posts: { index_section_id: nil })
    @unsectioned_posts = @unsectioned_posts.select("posts.*, index_posts.id as index_post_id, index_posts.section_order as section_order")
    @unsectioned_posts = @unsectioned_posts.order('index_posts.section_order ASC')
  end
end
