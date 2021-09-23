class BoardPresenter
  attr_reader :continuity

  def initialize(continuity)
    @continuity = continuity
  end

  def as_json(options={})
    return {} unless continuity
    json = continuity.as_json_without_presenter(only: [:id, :name])
    return json unless options[:include].present?
    return json unless options[:include].include?(:board_sections)
    # TODO what if lots of sections?
    json.merge(board_sections: continuity.board_sections.ordered)
  end
end
