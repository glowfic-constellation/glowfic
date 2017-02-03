class BoardPresenter
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def as_json(*args, **kwargs)
    return {} unless board
    # TODO what if lots of sections?
    { id: board.id,
      board_sections: board.board_sections.order('section_order asc') }
  end
end
