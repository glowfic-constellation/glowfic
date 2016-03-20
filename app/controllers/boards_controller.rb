class BoardsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :mark]
  before_filter :set_available_cowriters, :only => :new

  def index
    @page_title = "Continuities"
  end

  def new
    @board = Board.new
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
      set_available_cowriters
      render :action => :new
    end
  end

  def show
    @board = Board.find_by_id(params[:id])
    unless @board
      flash[:error] = "Continuity could not be found."
      redirect_to boards_path and return
    end

    @page_title = @board.name
    @posts = @board.posts.order('updated_at desc').select do |post|
      post.visible_to?(current_user)
    end.first(25)
  end

  def mark
    board = Board.find_by_id(params[:board_id])
    unless board
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
    @page_title = "New Continuity"
    @users = User.order(:username) - [current_user]
    use_javascript('boards')
  end
end
