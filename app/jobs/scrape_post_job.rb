require "#{Rails.root}/lib/post_scraper"

class ScrapePostJob < BaseJob
  @queue = :low
  @retry_limit = 3
  @expire_retry_key_after = 3600

  def self.process(url, board_id, section_id, status, importer_id)
    scraper = PostScraper.new(url, board_id, section_id, status)
    scraped_post = scraper.scrape!
    url = Rails.application.routes.url_helpers.post_url(scraped_post, host: ENV['DOMAIN_NAME'] || 'localhost:3000', protocol: 'https')
    Message.send_site_message(importer_id, 'Post import succeeded', "Your post was successfully imported! <a href='#{url}'>View it here</a>.")
  end

  def self.notify_exception(exception, url, board_id, section_id, status, importer_id)
    if (importer = User.find_by_id(importer_id))
      message = "The url #{url} could not be successfully scraped. "
      message += exception.message if exception.is_a?(UnrecognizedUsernameError)
      Message.send_site_message(importer_id, 'Post import failed', message)
    end
    super
  end
end
