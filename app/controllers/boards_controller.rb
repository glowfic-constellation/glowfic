# frozen_string_literal: true
class BoardsController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :find_board, only: [:show, :edit, :update, :destroy]
  before_filter :set_available_cowriters, only: [:new, :edit]
  before_filter :require_permission, only: [:edit, :update, :destroy]

  def index
    if params[:user_id].present?
      unless (@user = User.find_by_id(params[:user_id]) || current_user)
        flash[:error] = "User could not be found."
        redirect_to root_path and return
      end

      @page_title = if @user.id == current_user.try(:id)
        "Your Continuities"
      else
        @user.username + "'s Continuities"
      end

      board_ids = BoardAuthor.where(user_id: @user.id, cameo: false).pluck('distinct board_id')
      arel = Board.arel_table
      where = arel[:creator_id].eq(@user.id).or(arel[:id].in(board_ids))
      @boards = Board.where(where).order('pinned DESC, LOWER(name)')
      @cameo_boards = Board.where(id: BoardAuthor.where(user_id: @user.id, cameo: true).pluck('distinct board_id')).order('pinned DESC, LOWER(name)')
    else
      @page_title = 'Continuities'
      @boards = Board.order('pinned DESC, LOWER(name)').paginate(page: page, per_page: 25)
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
    render :action => :new
  end

  def show
    @page_title = @board.name
    @board_sections = @board.board_sections.order('section_order asc')
    order = 'section_order asc, tagged_at asc'
    order = 'tagged_at desc' unless @board.ordered?
    @posts = posts_from_relation(@board.posts.where(section_id: nil).order(order), false)
  end

  def edit
    @page_title = 'Edit Continuity: ' + @board.name
    use_javascript('boards/edit')
    @board_sections = @board.board_sections.order('section_order asc')
    unless @board.open_to_anyone? && @board_sections.empty?
      @unsectioned_posts = @board.posts.where(section_id: nil).order('section_order asc')
    end
  end

  def update
    if @board.update_attributes(board_params)
      flash[:success] = "Continuity saved!"
      redirect_to board_path(@board)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Continuity could not be created."
      flash.now[:error][:array] = @board.errors.full_messages
      @page_title = 'Edit Continuity: ' + @board.name_was
      set_available_cowriters
      use_javascript('board_sections')
      @board_sections = @board.board_sections.order('section_order')
      render :action => :edit
    end
  end

  def destroy
    @board.destroy
    flash[:success] = "Continuity deleted."
    redirect_to boards_path
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
    @authors = @cameos = User.order(:username)
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
