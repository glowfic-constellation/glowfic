require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Glowfic
  ALLOWED_TAGS = %w(b i u sub sup del hr p br div span pre code h1 h2 h3 h4 h5 h6 ul ol li dl dt dd a img blockquote q table td th tr strike s strong em big small font cite abbr var samp kbd mark ruby rp rt bdo wbr)
  ALLOWED_ATTRIBUTES = {
    :all => %w(xml:lang class style title lang dir),
    "hr" => %w(width),
    "li" => %w(value),
    "ol" => %w(reversed start type),
    "a" => %w(href hreflang rel target type),
    "del" => %w(cite datetime),
    "table" => %w(width),
    "td" => %w(abbr width),
    "th" => %w(abbr width),
    "blockquote" => %w(cite),
    "cite" => %w(href)
  }

  class WrittenScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = ALLOWED_TAGS
    end

    def scrub_attribute?(name, node)
      node_name = node.name.downcase
      name = name.downcase
      return false if ALLOWED_ATTRIBUTES[:all].include?(name)
      !ALLOWED_ATTRIBUTES[node_name].try(:include?, name)
    end

    def scrub_attributes(node)
      node.attribute_nodes.each do |attr|
        attr.remove if scrub_attribute?(attr.name, node)
        scrub_attribute(node, attr)
      end

      scrub_css_attribute(node)
    end
  end

  class DescriptionScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w(a)
      self.attributes = %w(href)
    end
  end

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
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

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # We cannot use the default Rails schema because we are using pg_search with
    # Postgres indexes using GIN and tsvector transformations.
    config.active_record.schema_format = :sql
  end
end
