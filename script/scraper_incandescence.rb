#!/usr/bin/env ruby

require Rails.root.join('lib', 'post_scraper')
require 'pp'

section_number = ARGV[0].to_i # only-process-this section number
board_id = (ARGV[1] || Board.where(name: 'Incandescence').first.try(:id)).to_i
section_index = 0

# processes the Incandescence index
# https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet
response = HTTParty.get('http://alicornutopia.dreamwidth.org/7441.html')
html_doc = Nokogiri::HTML(response.body)

main_list = html_doc.css('.entry-content i')
main_list.each do |section|
  # restrict to specified section if provided
  section_index += 1
  next if section_number > 0 && section_index != section_number

  # don't reprocess already processed sections
  next if BoardSection.where(board_id: board_id, section_order: section_index).exists?

  # don't crash on final empty section
  section_title = section.content.strip
  next unless section_title.present?
  pp "Importing section #{section_title}"

  links = section.parent.css('li')
  board_section = BoardSection.create!(board_id: board_id, name: section_title, section_order: section_index, status: 1)
  links.each do |link|
    url = link.at_css('a').attribute('href').value
    scraper = PostScraper.new(url, board_id, board_section.id, nil, false, true)
    scraper.scrape!
  end
end
