class BoardsController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :set_available_cowriters, only: [:new, :edit]
  before_filter :find_board, only: [:show, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :update, :destroy]

  def index
    @page_title = "Continuities"
  end

  def new
    @board = Board.new
    @page_title = "New Continuity"
  end

  def create
    @board = Board.new(params[:board])
    @board.creator = current_user

    if @board.save
      flash[:success] = "Continuity created!"
      redirect_to boards_path
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Continuity could not be created."
      flash.now[:error][:array] = @board.errors.full_messages
      @page_title = "New Continuity"
      set_available_cowriters
      render :action => :new
    end
  end

  def show
    @page_title = @board.name
    @posts = @board.posts.includes(:user, :last_user).order('tagged_at desc').paginate(per_page: 25, page: page)
  end

  def edit
    @page_title = "Edit Continuity"
  end

  def update
    if @board.update_attributes(params[:board])
      flash[:success] = "Continuity saved!"
      redirect_to board_path(@board)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Continuity could not be created."
      flash.now[:error][:array] = @board.errors.full_messages
      @page_title = "Edit Continuity"
      set_available_cowriters
      render :action => :edit
    end
  end

  def destroy
    @board.destroy
    flash[:success] = "Continuity deleted."
    redirect_to boards_path
  end

  def mark
    unless board = Board.find_by_id(params[:board_id])
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
    @users = User.order(:username) - [current_user]
    use_javascript('boards')
  end

  def find_board
    unless @board = Board.find_by_id(params[:id])
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
end
