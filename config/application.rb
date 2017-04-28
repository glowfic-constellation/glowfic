# this is a patch for the following bug:
# https://github.com/rails/rails/issues/25010
# TODO remove with Rails 4
class Hash
  undef_method :to_proc if self.method_defined?(:to_proc)
end

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Glowfic
  ALLOWED_TAGS = ["b", "i", "u", "sub", "sup", "del", "hr", "p", "br", "div", "span", "pre", "code", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "li", "dl", "dt", "dd", "a", "img", "blockquote", "q", "table", "td", "th", "tr", "strike", "s", "strong", "em", "big", "small", "font",  "cite", "abbr", "var", "samp", "kbd", "mark", "ruby", "rp", "rt", "bdo", "wbr"]
  POST_CONTENT_SANITIZER = Sanitize::Config.merge(Sanitize::Config::RELAXED,
    :elements => ALLOWED_TAGS,
    :attributes => {
      :all => ["xml:lang", "class", "style", "title", "lang", "dir"],
      "hr" => ["width"],
      "li" => ["value"],
      "ol" => ["reversed", "start", "type"],
      "a" => ["href", "hreflang", "rel", "target", "type"],
      "del" => ["cite", "datetime"],
      "table" => ["width"],
      "td" => ["abbr", "width"],
      "th" => ["abbr", "width"],
      "blockquote" => ["cite"],
      "cite" => ["href"]
    }
  )

  class Application < Rails::Application
    config.assets.enabled = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    config.time_zone = 'Eastern Time (US & Canada)'
    config.active_record.default_timezone = :local

    config.action_view.sanitized_allowed_tags = Glowfic::ALLOWED_TAGS
    config.after_initialize do
      ActionView::Base.sanitized_allowed_attributes += ['style', 'target']
    end
    config.middleware.use Rack::Pratchett

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # We cannot use the default Rails schema because we are using pg_search with
    # Postgres indexes using GIN and tsvector transformations.
    config.active_record.schema_format = :sql
  end
end
