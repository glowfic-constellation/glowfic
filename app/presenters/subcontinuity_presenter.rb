class SubcontinuityPresenter
  attr_reader :subcontinuity

  def initialize(subcontinuity)
    @subcontinuity = subcontinuity
  end

  def as_json(_options={})
    return {} unless subcontinuity
    { id: subcontinuity.id,
      name: subcontinuity.name,
      order: subcontinuity.section_order }
  end
end
