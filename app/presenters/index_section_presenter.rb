# frozen_string_literal: true
class IndexSectionPresenter
  attr_reader :index_section

  def initialize(index_section)
    @index_section = index_section
  end

  def as_json(_options={})
    {
      id: index_section.id,
      name: index_section.name,
      description: index_section.description,
      order: index_section.section_order,
    }
  end
end
