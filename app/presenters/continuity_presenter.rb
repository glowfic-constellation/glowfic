class ContinuityPresenter
  attr_reader :continuity

  def initialize(continuity)
    @continuity = continuity
  end

  def as_json(options={})
    return {} unless continuity
    continuity_json = continuity.as_json_without_presenter(only: [:id, :name])
    return continuity_json unless options[:include].present?
    return continuity_json unless options[:include].include?(:subcontinuities)
    # TODO what if lots of sections?
    continuity_json.merge(subcontinuities: continuity.subcontinuities.ordered)
  end
end
