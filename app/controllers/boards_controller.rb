# frozen_string_literal: true
class BoardsController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :find_board, only: [:show, :edit, :update, :destroy]
  before_action :set_available_cowriters, only: [:new, :edit]
  before_action :require_permission, only: [:edit, :update, :destroy]

  def index
    if params[:user_id].present?
      unless (@user = User.active.find_by_id(params[:user_id]))
        flash[:error] = "User could not be found."
        redirect_to root_path and return
      end

      @page_title = if @user.id == current_user.try(:id)
        "Your Continuities"
      else
        @user.username + "'s Continuities"
      end

      board_ids = BoardAuthor.where(user_id: @user.id, cameo: false).select(:board_id).distinct.pluck(:board_id)
      @boards = Board.where(creator_id: @user.id).or(Board.where(id: board_ids)).ordered
      @cameo_boards = Board.where(id: BoardAuthor.where(user_id: @user.id, cameo: true).select(:board_id).distinct.pluck(:board_id)).ordered
    else
      @page_title = 'Continuities'
      @boards = Board.ordered.paginate(page: page, per_page: 25)
    end
  end

  def new
    @board = Board.new
    @board.creator = current_user
    @page_title = 'New Continuity'
  end

  def create
    @board = Board.new(board_params)
    @board.creator = current_user

    begin
      @board.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Continuity could not be created.",
        array: @board.errors.full_messages
      }
      @page_title = 'New Continuity'
      set_available_cowriters
      render :new
    else
      flash[:success] = "Continuity created!"
      redirect_to boards_path
    end
  end

  def show
    @page_title = @board.name
    @board_sections = @board.board_sections.ordered
    board_posts = @board.posts.where(section_id: nil)
    if @board.ordered?
      board_posts = board_posts.ordered_in_section
    else
      board_posts = board_posts.ordered
    end
    @posts = posts_from_relation(board_posts, no_tests: false)
    @meta_og = og_data
    use_javascript('boards/show')
  end

  def edit
    @page_title = 'Edit Continuity: ' + @board.name
    use_javascript('boards/edit')
    @board_sections = @board.board_sections.ordered
    unless @board.open_to_anyone? && @board_sections.empty?
      @unsectioned_posts = @board.posts.where(section_id: nil).ordered_in_section
    end
  end

  def update
    begin
      @board.update!(board_params)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Continuity could not be created.",
        array: @board.errors.full_messages
      }
      @page_title = 'Edit Continuity: ' + @board.name_was
      set_available_cowriters
      use_javascript('board_sections')
      @board_sections = @board.board_sections.ordered
      render :edit
    else
      flash[:success] = "Continuity saved!"
      redirect_to board_path(@board)
    end
  end

  def destroy
    begin
      @board.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Continuity could not be deleted.",
        array: @board.errors.full_messages
      }
      redirect_to board_path(@board)
    else
      flash[:success] = "Continuity deleted."
      redirect_to boards_path
    end
  end

  def mark
    unless (board = Board.find_by_id(params[:board_id]))
      flash[:error] = "Continuity could not be found."
      redirect_to unread_posts_path and return
    end

    if params[:commit] == "Mark Read"
      Board.transaction do
        board.mark_read(current_user)
        read_time = board.last_read(current_user)
        post_views = PostView.joins(post: :board).where(user: current_user, boards: {id: board.id})
        post_views.update_all(read_at: read_time, updated_at: read_time) # rubocop:disable Rails/SkipsModelValidations
      end
      flash[:success] = "#{board.name} marked as read."
    elsif params[:commit] == "Hide from Unread"
      board.ignore(current_user)
      flash[:success] = "#{board.name} hidden from this page."
    else
      flash[:error] = "Please choose a valid action."
    end
    redirect_to unread_posts_path
  end

  private

  def set_available_cowriters
    @authors = @cameos = User.active.ordered
    if @board
      @authors -= @board.cameos
      @cameos -= @board.coauthors
      @authors -= [@board.creator]
      @cameos -= [@board.creator]
    else
      @authors -= [current_user]
      @cameos -= [current_user]
    end
    use_javascript('boards/editor')
  end

  def find_board
    unless (@board = Board.find_by_id(params[:id]))
      flash[:error] = "Continuity could not be found."
      redirect_to boards_path and return
    end
  end

  def require_permission
    unless @board.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit that continuity."
      redirect_to board_path(@board) and return
    end
  end

  def og_data
    metadata = []
    metadata << @board.writers.reject(&:deleted?).pluck(:username).sort_by(&:downcase).join(', ') unless @board.open_to_anyone?
    post_count = @board.posts.where(privacy: Concealable::PUBLIC).count
    stats = "#{post_count} " + "post".pluralize(post_count)
    section_count = @board.board_sections.count
    stats += " in #{section_count} " + "section".pluralize(section_count) if section_count > 0
    metadata << stats
    desc = [metadata.join(' – ')]
    desc << generate_short(@board.description) if @board.description.present?
    {
      url: board_url(@board),
      title: @board.name,
      description: desc.join("\n"),
    }
  end

  def board_params
    params.fetch(:board, {}).permit(:name, :description, coauthor_ids: [], cameo_ids: [])
  end
end
