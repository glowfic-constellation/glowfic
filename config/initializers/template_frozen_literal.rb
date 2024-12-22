# reduce memory use of strings in ActionView Templates
# https://github.com/rails/rails/blob/v7.2.2/actionview/lib/action_view/template.rb#L181
ActionView::Template.frozen_string_literal = true
