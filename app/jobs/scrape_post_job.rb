class ScrapePostJob < ApplicationJob
  queue_as :low

  def perform(url, params, user:)
    Resque.logger.debug "Starting scrape for #{url}"
    scraper = PostScraper.new(url, **params.symbolize_keys)
    scraped_post = scraper.scrape!
    Notification.notify_user(user, :import_success, post: scraped_post)
  end

  def self.notify_exception(exception, url, params, user:)
    Resque.logger.warn "Failed to import #{url}: #{exception.message}"
    super unless user
    post = exception.is_a?(AlreadyImportedError) ? Post.find_by(id: exception.post_id) : nil
    Notification.notify_user(user, :import_fail, error: exception.message, post: post)
    super
  end

  def self.view_post(post_id)
    host = ENV.fetch('DOMAIN_NAME', 'localhost:3000')
    url = Rails.application.routes.url_helpers.post_url(post_id, host: host, protocol: 'https')
    "<a href='#{url}'>View it here</a>."
  end
end
