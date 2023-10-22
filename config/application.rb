require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Glowfic
  ALLOWED_TAGS = %w(b i u sub sup del ins hr p br div span pre code h1 h2 h3 h4 h5 h6 ul ol li dl dt dd a img blockquote q table tbody td th thead tr
                    strike s strong em big small font cite abbr var samp kbd mark ruby rp rt bdo wbr details summary)
  ALLOWED_ATTRIBUTES = {
    :all         => %w(xml:lang class style title lang dir),
    "hr"         => %w(width),
    "li"         => %w(value),
    "ol"         => %w(reversed start type),
    "a"          => %w(href hreflang rel target type),
    "del"        => %w(cite datetime),
    "table"      => %w(width),
    "td"         => %w(abbr width colspan rowspan),
    "th"         => %w(abbr width colspan rowspan),
    "blockquote" => %w(cite),
    "cite"       => %w(href),
  }

  DISCORD_LINK_CONSTELLATION = 'https://discord.gg/RWUPXQD'

  module Sanitizers
    WRITTEN_CONF = Sanitize::Config.merge(
      Sanitize::Config::RELAXED,
      elements: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES,
    )

    def self.written(text)
      Sanitize.fragment(text, WRITTEN_CONF).html_safe # rubocop:disable Rails/OutputSafety
    end

    DESCRIPTION_CONF = Sanitize::Config.merge(
      Sanitize::Config::RELAXED,
      elements: ['a'],
      attributes: { 'a' => ['href'] },
    )

    def self.description(text)
      Sanitize.fragment(text, DESCRIPTION_CONF).html_safe # rubocop:disable Rails/OutputSafety
    end

    def self.full(text)
      Sanitize.fragment(text).html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # fix issue with optional: false on reply belongs_to post
    config.active_record.has_many_inversing = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Eastern Time (US & Canada)'
    # config.eager_load_paths << Rails.root.join("extras")

    config.action_view.sanitized_allowed_tags = Glowfic::ALLOWED_TAGS
    config.action_view.sanitized_allowed_attributes = %w(href src width height alt cite datetime title class name xml:lang abbr style target)
    config.middleware.use Rack::Pratchett
    config.middleware.use Rack::Deflater

    # redis-rails does not support cache versioning
    config.active_record.cache_versioning = false
    config.active_record.collection_cache_versioning = false
  end
end
