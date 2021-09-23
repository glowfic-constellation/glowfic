# frozen_string_literal: true
class BoardsController < ApplicationController
  before_action :login_required, except: [:index, :show, :search]
  before_action :find_model, only: [:show, :edit, :update, :destroy]
  before_action :editor_setup, only: [:new, :edit]
  before_action :require_create_permission, only: [:new, :create]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]

  def index
    if params[:user_id].present?
      unless (@user = User.active.full.find_by_id(params[:user_id]))
        flash[:error] = "User could not be found."
        redirect_to root_path and return
      end

      @page_title = if @user.id == current_user.try(:id)
        "Your Continuities"
      else
        @user.username + "'s Continuities"
      end

      continuity_ids = BoardAuthor.where(user_id: @user.id, cameo: false).select(:board_id).distinct.pluck(:board_id)
      @continuities = continuities_from_relation(Board.where(creator_id: @user.id).or(Board.where(id: continuity_ids)))
      cameo_ids = BoardAuthor.where(user_id: @user.id, cameo: true).select(:board_id).distinct.pluck(:board_id)
      @cameo_continuities = continuities_from_relation(Board.where(id: cameo_ids))
    else
      @page_title = 'Continuities'
      @continuities = continuities_from_relation(Board.all).paginate(page: page)
    end
  end

  def new
    @continuity = Board.new(creator: current_user)
    @page_title = 'New Continuity'
  end

  def create
    @continuity = Board.new(permitted_params)
    @continuity.creator = current_user

    begin
      @continuity.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Continuity could not be created.",
        array: @continuity.errors.full_messages,
      }
      @page_title = 'New Continuity'
      editor_setup
      render :new
    else
      flash[:success] = "Continuity created!"
      redirect_to continuities_path
    end
  end

  def show
    @page_title = @continuity.name
    @board_sections = @continuity.board_sections.ordered
    @posts = @continuity.posts.where(section_id: nil)
    if @continuity.ordered?
      @posts = @posts.ordered_in_section
    else
      @posts = @posts.ordered
    end
    @posts = posts_from_relation(@posts, no_tests: false)
    @meta_og = og_data
    use_javascript('boards/show')
  end

  def edit
    @page_title = 'Edit Continuity: ' + @continuity.name
    use_javascript('boards/edit')
    @board_sections = @continuity.board_sections.ordered
    @unsectioned_posts = @continuity.posts.where(section_id: nil).ordered_in_section if @continuity.ordered?
  end

  def update
    begin
      @continuity.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Continuity could not be created.",
        array: @continuity.errors.full_messages,
      }
      @page_title = 'Edit Continuity: ' + @continuity.name_was
      editor_setup
      use_javascript('board_sections')
      @board_sections = @continuity.board_sections.ordered
      render :edit
    else
      flash[:success] = "Continuity saved!"
      redirect_to continuity_path(@continuity)
    end
  end

  def destroy
    begin
      @continuity.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Continuity could not be deleted.",
        array: @continuity.errors.full_messages,
      }
      redirect_to continuity_path(@continuity)
    else
      flash[:success] = "Continuity deleted."
      redirect_to continuities_path
    end
  end

  def mark
    unless (continuity = Board.find_by_id(params[:board_id]))
      flash[:error] = "Continuity could not be found."
      redirect_to unread_posts_path and return
    end

    if params[:commit] == "Mark Read"
      Board.transaction do
        continuity.mark_read(current_user)
        read_time = continuity.last_read(current_user)
        post_views = Post::View.joins(post: :board).where(user: current_user, boards: { id: continuity.id })
        post_views.update_all(read_at: read_time, updated_at: read_time) # rubocop:disable Rails/SkipsModelValidations
      end
      flash[:success] = "#{continuity.name} marked as read."
    elsif params[:commit] == "Hide from Unread"
      continuity.ignore(current_user)
      flash[:success] = "#{continuity.name} hidden from this page."
    else
      flash[:error] = "Please choose a valid action."
    end
    redirect_to unread_posts_path
  end

  def search
    @page_title = 'Search Continuities'
    @user = User.active.where(id: params[:author_id]).ordered if params[:author_id].present?
    use_javascript('boards/search')
    return unless params[:commit].present?

    searcher = Board::Searcher.new
    @search_results = searcher.search(params)
    @search_results = continuities_from_relation(@search_results).paginate(page: page)
  end

  private

  def editor_setup
    @coauthors = @cameos = User.active.ordered
    if @continuity
      @coauthors -= @continuity.cameos
      @cameos -= @continuity.writers
      @coauthors -= [@continuity.creator]
      @cameos -= [@continuity.creator]
    else
      @coauthors -= [current_user]
      @cameos -= [current_user]
    end
    use_javascript('boards/editor')
  end

  def find_model
    return if (@continuity = Board.find_by_id(params[:id]))
    flash[:error] = "Continuity could not be found."
    redirect_to continuities_path
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create continuities."
    redirect_to continuities_path
  end

  def require_edit_permission
    return if @continuity.editable_by?(current_user)
    flash[:error] = "You do not have permission to edit that continuity."
    redirect_to continuity_path(@continuity)
  end

  def continuities_from_relation(relation)
    sql = <<~SQL.squish
      boards.*,
      (SELECT MAX(tagged_at) FROM posts WHERE posts.board_id = boards.id) AS tagged_at
    SQL
    relation
      .ordered
      .select(sql)
      .includes(:writers)
  end

  def og_data
    metadata = []
    metadata << @continuity.writers.where.not(deleted: true).ordered.pluck(:username).join(', ') if @continuity.authors_locked?
    post_count = @continuity.posts.privacy_public.count
    stats = "#{post_count} " + "post".pluralize(post_count)
    section_count = @continuity.board_sections.count
    stats += " in #{section_count} " + "section".pluralize(section_count) if section_count > 0
    metadata << stats
    desc = [metadata.join(' – ')]
    desc << generate_short(@continuity.description) if @continuity.description.present?
    {
      url: continuity_url(@continuity),
      title: @continuity.name,
      description: desc.join("\n"),
    }
  end

  def permitted_params
    params.fetch(:board, {}).permit(:name, :description, :authors_locked, coauthor_ids: [], cameo_ids: [])
  end
end
