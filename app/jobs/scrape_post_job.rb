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
end
