# frozen_string_literal: true
class BoardSectionsController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_section, except: [:new, :create]
  before_filter :require_permission, except: [:show, :update]

  def new
    @board_section = BoardSection.new(board_id: params[:board_id])
    @page_title = 'New Section'
  end

  def create
    @board_section = BoardSection.new(params[:board_section])
    unless @board_section.board.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this continuity."
      redirect_to boards_path and return
    end

    if @board_section.save
      flash[:success] = "New section, #{@board_section.name}, has successfully been created for #{@board_section.board.name}."
      redirect_to edit_board_path(@board_section.board)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Section could not be created."
      flash.now[:error][:array] = @board_section.errors.full_messages
      @page_title = 'New Section'
      render action: :new
    end
  end

  def show
    @page_title = @board_section.name
    @posts = posts_from_relation(@board_section.posts.order('section_order asc'))
  end

  def edit
    @page_title = 'Edit ' + @board_section.name
    use_javascript('board_sections')
  end

  def update
    @board_section.assign_attributes(params[:board_section])
    require_permission
    return if performed?
    if @board_section.save
      flash[:success] = "#{@board_section.name} has been successfully updated."
      redirect_to board_section_path(@board_section)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Section could not be updated."
      flash.now[:error][:array] = @board_section.errors.full_messages
      @page_title = 'Edit ' + @board_section.name_was
      render action: :edit
    end
  end

  def destroy
    @board_section.destroy
    flash[:success] = "Section deleted."
    redirect_to edit_board_path(@board_section.board)
  end

  private

  def find_section
    @board_section = BoardSection.find_by_id(params[:id])
    unless @board_section
      flash[:error] = "Section not found."
      redirect_to boards_path and return
    end
  end

  def require_permission
    board = @board_section.try(:board) || Board.find_by_id(params[:board_id])
    if board && !board.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this continuity."
      redirect_to boards_path and return
    end
  end
end
