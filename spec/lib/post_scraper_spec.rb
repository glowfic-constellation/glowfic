require "spec_helper"
require "#{Rails.root}/lib/post_scraper"

RSpec.describe PostScraper do
  it "should add view to url" do
    scraper = PostScraper.new('http://glowfic.dreamwidth.org/29291.html')
    expect(scraper.url).to include('?view=flat')
  end

  it "should not change url if view is present" do
    url = 'http://glowfic.dreamwidth.org/29291.html?view=flat'
    scraper = PostScraper.new(url)
    expect(scraper.url.sub('view=flat', '')).not_to include('view=flat')
    expect(scraper.url.gsub("&style=site","").length).to eq(url.length)
  end

  it "should add site style to the url" do
    url = 'http://glowfic.dreamwidth.org/29291.html?view=flat'
    scraper = PostScraper.new(url)
    expect(scraper.url).to include('&style=site')
  end

  it "should not change url if site style is present" do
    url = 'http://glowfic.dreamwidth.org/29291.html?view=flat&style=site'
    scraper = PostScraper.new(url)
    expect(scraper.url.length).to eq(url.length)
  end
end
