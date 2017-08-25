class BoardSectionPresenter
  attr_reader :board_section

  def initialize(board_section)
    @board_section = board_section
  end

  def as_json(_options={})
    return {} unless board_section
    { id: board_section.id,
      name: board_section.name,
      order: board_section.section_order }
  end
end
