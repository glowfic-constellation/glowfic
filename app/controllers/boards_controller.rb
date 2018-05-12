# frozen_string_literal: true
class BoardsController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :find_board, only: [:show, :edit, :update, :destroy]
  before_action :set_available_cowriters, only: [:new, :edit]
  before_action :require_permission, only: [:edit, :update, :destroy]

  def index
    if params[:user_id].present?
      unless (@user = User.find_by_id(params[:user_id]) || current_user) && !@user.deleted?
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

    if @board.save
      flash[:success] = "Continuity created!"
      redirect_to boards_path and return
    end

    flash.now[:error] = {}
    flash.now[:error][:message] = "Continuity could not be created."
    flash.now[:error][:array] = @board.errors.full_messages
    @page_title = 'New Continuity'
    set_available_cowriters
    render :new
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
    if @board.update(board_params)
      flash[:success] = "Continuity saved!"
      redirect_to board_path(@board)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Continuity could not be created."
      flash.now[:error][:array] = @board.errors.full_messages
      @page_title = 'Edit Continuity: ' + @board.name_was
      set_available_cowriters
      use_javascript('board_sections')
      @board_sections = @board.board_sections.ordered
      render :edit
    end
  end

  def destroy
    @board.destroy!
    flash[:success] = "Continuity deleted."
    redirect_to boards_path
  rescue ActiveRecord::RecordNotDestroyed
    flash[:error] = {}
    flash[:error][:message] = "Continuity could not be deleted."
    flash[:error][:array] = @board.errors.full_messages
    redirect_to board_path(@board)
  end

  def mark
    unless (board = Board.find_by_id(params[:board_id]))
      flash[:error] = "Continuity could not be found."
      redirect_to unread_posts_path and return
    end

    if params[:commit] == "Mark Read"
      board.mark_read(current_user)
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
    @authors = @cameos = User.ordered
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

  def board_params
    params.fetch(:board, {}).permit(:name, :description, coauthor_ids: [], cameo_ids: [])
  end
end
