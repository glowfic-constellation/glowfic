#!/usr/bin/env ruby

require "#{Rails.root}/lib/post_scraper"
require 'pp'

section_number = ARGV[0].to_i # only-process-this section number
board_id = (ARGV[1] || 1).to_i
section_index = 0

# first argument is only-process-this section number
section_number = ARGV[0].to_i
section_index = 0

# processes the Effulgence index
# https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet
response = HTTParty.get('http://edgeofyourseat.dreamwidth.org/2121.html?style=site')
html_doc = Nokogiri::HTML(response.body)
main_list = html_doc.at_css('.entry-content ol')
main_list.children.each do |section|
  # skip empty nodes
  next if section.content.blank?

  # restrict to specified section if provided
  section_index += 1
  next if section_number > 0 && section_index != section_number

  # don't reprocess already processed sections
  next if BoardSection.where(board_id: board_id, section_order: section_index).exists?

  # don't crash on final empty section
  section_title = section.children[0].content.strip
  next unless section_title.present?
  pp "Importing section #{section_title}"

  # process sections that are exclusively a single post with multiple threads
  if section.children[1].name == 'a'
    link = section.children[1]
    url = link.attribute('href').value
    section_title = link.inner_html
    board_section = BoardSection.create!(board_id: board_id, name: section_title, section_order: section_index, status: 1)
    scraper = PostScraper.new(url, board_id, board_section.id)
    scraper.scrape!
    next
  end

  # process sections with multiple posts
  links = section.children[1].css('li')
  section_active = links.last.children.size == 1 && links.last.children.first.name == 'text' && links.last.children.first.content.strip == '+'
  section_status = section_active ? 0 : 1
  board_section = BoardSection.create!(board_id: board_id, name: section_title, section_order: section_index, status: section_status)
  links.each_with_index do |link, index|
    break if section_active && link == links.last

    url = link.at_css('a').attribute('href').value
    next if url.include?('#cmt') or url.include?('thread=')

    if link.children.last.name == 'ul'
      import_threaded_thread(url, board_section, index, link, alicorn_characters, kappa_characters)
    else
      title = link.content
      title = title[0..-2] if is_active = link.content.strip.last == '+'
      status = is_active ? Post::STATUS_ACTIVE : Post::STATUS_COMPLETE
      scraper = PostScraper.new(url, board_id, board_section.id, status)
      scraper.scrape!
    end
  end
end
