class BoardSectionsController < CrudController
    # TODO on create/update
    # unless @board_section.board.nil? || @board_section.board.editable_by?(current_user)
    #   flash[:error] = "You do not have permission to edit this continuity."
    #   redirect_to boards_path and return
    # end
  def show
    super
    @posts = posts_from_relation(@board_section.posts.ordered_in_section)
    @meta_og = og_data
  end

  private

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
