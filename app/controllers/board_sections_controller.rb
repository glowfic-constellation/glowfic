class BoardSectionsController < ApplicationController
  before_filter :login_required, except: :show

  def new
    @board_section = BoardSection.new(board_id: params[:board_id])
    @page_title = "New Section"
  end

  def create
    @board_section = BoardSection.new(params[:board_section])
    if @board_section.save
      flash[:success] = "New #{@board_section.board.name} section #{@board_section.name} has been successfully created."
      redirect_to board_path(@board_section.board)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Section could not be created."
      flash.now[:error][:array] = @board_section.errors.full_messages
      render action: :new
    end
  end

  def show
    @board_section = BoardSection.find_by_id(params[:id])
    use_javascript('boards')
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private
end
