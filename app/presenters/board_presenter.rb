# frozen_string_literal: true
class BoardPresenter
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def as_json(options={})
    board_json = board.as_json_without_presenter(only: [:id, :name])
    includes = options[:include] || []
    if includes.include?(:ordered)
      board_json[:authors_locked] = board.authors_locked?
      board_json[:ordered] = board.ordered?
    end
    return board_json unless includes.include?(:board_sections)
    # TODO what if lots of sections?
    board_json.merge(board_sections: board.board_sections.ordered)
  end
end
