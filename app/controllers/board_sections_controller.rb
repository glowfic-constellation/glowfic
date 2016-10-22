class BoardSectionsController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_section, except: [:new, :create]
  before_filter :require_permission, except: [:show, :update]

  def new
    @board_section = BoardSection.new(board_id: params[:board_id])
    @page_title = "New Section"
  end

  def create
    reorder_sections and return if params[:commit] == "reorder"

    @board_section = BoardSection.new(params[:board_section])
    unless @board_section.board.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this continuity."
      redirect_to boards_path and return
    end

    if @board_section.save
      flash[:success] = "New #{@board_section.board.name} section #{@board_section.name} has been successfully created."
      redirect_to edit_board_path(@board_section.board)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Section could not be created."
      flash.now[:error][:array] = @board_section.errors.full_messages
      render action: :new
    end
  end

  def show
    @page_title = @board_section.name
    @posts = @board_section.posts.includes(:user, :last_user, :content_warnings).order('section_order asc').paginate(per_page: 25, page: page)
  end

  def edit
    @page_title = 'Edit ' + @board_section.name
    use_javascript('board_sections')
  end

  def update
    @board_section.assign_attributes(params[:board_section])
    require_permission
    return if performed?
    if @board_section.valid?
      @board_section.save
      flash[:success] = "#{@board_section.name} has been successfully updated."
      redirect_to board_section_path(@board_section)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Section could not be updated."
      flash.now[:error][:array] = @board_section.errors.full_messages
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

  def reorder_sections
    valid_types = ['Post', 'BoardSection']
    render json: {} and return if params[:changes].any? { |key, el| !(valid_types.include?(el[:type])) }

    if params[:changes].any? { |key, el| el[:order].nil? }
      ExceptionNotifier.notify_exception(Exception.new, data: params)
    end

    BoardSection.transaction do
      params[:changes].each do |section_id, change_info|
        section_order = change_info[:order]
        section_type = change_info[:type]
        section = section_type.constantize.find_by_id(section_id)
        next unless section
        section.update_attributes(section_order: section_order)
      end
    end
    render json: {}
  end
end
