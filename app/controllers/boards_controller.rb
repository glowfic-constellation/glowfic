class BoardsController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :find_board, only: [:show, :edit, :update, :destroy]
  before_filter :set_available_cowriters, only: [:new, :edit]
  before_filter :require_permission, only: [:edit, :update, :destroy]

  def index
    @page_title = "Continuities"
  end

  def new
    @board = Board.new
    @board.creator = current_user
    @page_title = "New Continuity"
  end

  def create
    @board = Board.new(params[:board])
    @board.creator = current_user

    if @board.save
      flash[:success] = "Continuity created!"
      redirect_to boards_path and return
    end

    flash.now[:error] = {}
    flash.now[:error][:message] = "Continuity could not be created."
    flash.now[:error][:array] = @board.errors.full_messages
    @page_title = "New Continuity"
    set_available_cowriters
    render :action => :new
  end

  def show
    respond_to do |format|
      format.json do
        render json: @board.board_sections.order('section_order asc').map { |s| [s.id, s.name] }
      end
      format.html do
        order = 'section_order asc, tagged_at asc'
        order = 'tagged_at desc' if @board.open_to_anyone?
        @page_title = @board.name
        @posts = @board.posts.includes(:user, :last_user).order(order).paginate(per_page: 25, page: page)
        @board_items = @board.board_sections + @board.posts.where(section_id: nil)
        @board_items.sort_by! { |item| item.section_order.to_i }
      end
    end
  end

  def edit
    @page_title = "Edit Continuity"
    gon.ajax_path = '/board_sections'
    use_javascript('board_sections')
    @board_items = @board.board_sections + @board.posts.where(section_id: nil)
    @board_items.sort_by! { |item| item.section_order.to_i }
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
    @authors = @cameos = User.order(:username)
    if @board
      @authors -= @board.coauthors.cameos
      @cameos -= @board.coauthors
      @authors -= [@board.creator]
      @cameos -= [@board.creator]
    else
      @authors -= [current_user]
      @cameos -= [current_user]
    end
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
