# frozen_string_literal: true
class BoardSectionsController < GenericController
  before_action(only: [:new, :create]) { require_edit_permission }

  def create
    @board_section = BoardSection.new(permitted_params)
    unless @board_section.board.nil? || @board_section.board.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this continuity."
      redirect_to boards_path and return
    end

    begin
      @board_section.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@board_section, action: 'created', now: true, class_name: 'Section')
      log_error(e) unless @board_section.errors.present?

      @page_title = 'New Section'
      render :new
    else
      flash[:success] = "New section, #{@board_section.name}, created for #{@board_section.board.name}."
      redirect_to edit_board_path(@board_section.board)
    end
  end

  def show
    super
    @posts = posts_from_relation(@board_section.posts.ordered_in_section)
    @meta_og = og_data
  end

  def update
    @board_section.assign_attributes(permitted_params)
    require_edit_permission
    return if performed?

    begin
      @board_section.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@board_section, action: 'updated', now: true, class_name: 'Section')
      log_error(e) unless @board_section.errors.present?

      @page_title = 'Edit ' + @board_section.name_was
      render :edit
    else
      flash[:success] = "Section updated."
      redirect_to board_section_path(@board_section)
    end
  end

  private

  def permitted_params
    params.fetch(:board_section, {}).permit(
      :board_id,
      :name,
      :description,
    )
  end

  def editor_setup
    if @board_section.present?
      use_javascript('board_sections')
      gon.section_id = @board_section.id
    end
  end

  def model_name
    'Section'
  end

  def model_class
    BoardSection
  end

  def require_edit_permission
    board = @board_section.try(:board) || Board.find_by_id(params[:board_id])
    if board && !board.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this continuity."
      redirect_to boards_path and return
    end
  end
  alias_method :require_delete_permission, :require_edit_permission

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

  def create_redirect
    edit_board_path(@board_section.board)
  end

  def update_redirect
    board_section_path(@board_section)
  end

  def destroy_redirect
    edit_board_path(@board_section.board)
  end

  def invalid_redirect
    boards_path
  end
end
