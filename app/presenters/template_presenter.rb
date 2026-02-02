# frozen_string_literal: true
class TemplatePresenter
  attr_reader :template

  def initialize(template)
    @template = template
  end

  def as_json(options={})
    template_json = template.as_json_without_presenter({ only: [:id, :name] }.reverse_merge(options))
    return template_json unless options[:dropdown]
    template_json.merge({
      dropdown: "#{template.name} (#{template.user.username})",
    })
  end
end
