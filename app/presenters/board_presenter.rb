class BoardPresenter
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def as_json(*args, **kwargs)
    return {} unless board
    sections = board.board_sections.order('section_order asc').map { |section| BoardSectionPresenter.new(section) }
    # TODO what if lots of sections?
    { id: board.id,
      board_sections: sections }
  end
end
