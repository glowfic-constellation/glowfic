# frozen_string_literal: true
class BoardSectionsController < GenericController

  def create
    @board_section = BoardSection.new(section_params)
    unless @board_section.board.nil? || @board_section.board.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this continuity."
      redirect_to boards_path and return
    end

    begin
      @board_section.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Section could not be created.",
        array: @board_section.errors.full_messages
      }
      @page_title = 'New Section'
      render :new
    else
      flash[:success] = "New section, #{@board_section.name}, has successfully been created for #{@board_section.board.name}."
      redirect_to edit_board_path(@board_section.board)
    end
  end

  def show
    super
    @posts = posts_from_relation(@board_section.posts.ordered_in_section)
    @meta_og = og_data
  end

  def update
    @board_section.assign_attributes(section_params)
    require_permission
    return if performed?

    begin
      @board_section.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Section could not be updated.",
        array: @board_section.errors.full_messages
      }
      @page_title = 'Edit ' + @board_section.name_was
      setup_editor
      render :edit
    else
      flash[:success] = "#{@board_section.name} has been successfully updated."
      redirect_to board_section_path(@board_section)
    end
  end


  private

  def og_data
    stats = []
    board = @board_section.board
    stats << board.writers.where.not(deleted: true).ordered.pluck(:username).join(', ') if board.authors_locked?
    post_count = @board_section.posts.where(privacy: Concealable::PUBLIC).count
    stats << "#{post_count} " + "post".pluralize(post_count)
    desc = [stats.join(' – ')]
    desc << generate_short(@board_section.description) if @board_section.description.present?
    {
      url: board_section_url(@board_section),
      title: "#{board.name} » #{@board_section.name}",
      description: desc.join("\n"),
    }
  end

  def model_params
    params.fetch(:board_section, {}).permit(
      :board_id,
      :name,
      :description,
    )
  end

  def setup_editor
    use_javascript('board_sections')
    gon.section_id = @board_section&.id
  end
end
