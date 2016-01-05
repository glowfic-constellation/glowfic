class BoardsController < ApplicationController
  before_filter :login_required, :only => :new
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
      flash.now[:error] = "Continuity could not be created."
      set_available_cowriters
      render :action => :new
    end
  end

  def show
    @board = Board.find_by_id(params[:id])
    @page_title = @board.name

    unless @board
      flash[:error] = "Continuity could not be found."
      redirect_to boards_path and return
    end

    @posts = @board.posts.order('id desc').select do |post|
      post.visible_to?(current_user)
    end
  end

  private

  def set_available_cowriters
    @page_title = "New Continuity"
    @users = User.order(:username) - [current_user]
    use_javascript('boards')
  end
end
