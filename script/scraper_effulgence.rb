#!/usr/bin/env ruby

require Rails.root.join('lib', 'post_scraper')
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

  section_title_obj = section.at_css('> a') || section.children[0]
  section_title = section_title_obj.content.strip
  # don't crash on final empty section
  next unless section_title.present?

  # don't reprocess already processed sections unless specified
  board_section = BoardSection.where(board_id: board_id, name: section_title).first
  next if section_number.zero? && board_section

  puts "# Importing section #{section_title}"

  # process sections
  list = section.at_css('ul, ol')
  links = list.css('> li')
  section_active = links.last.children.size == 1 && links.last.children.first.name == 'text' && links.last.children.first.content.strip == '+'
  section_status = section_active ? Post::STATUS_ACTIVE : Post::STATUS_COMPLETE
  board_section ||= BoardSection.create!(board_id: board_id, name: section_title, section_order: section_index - 1, status: section_status)

  # process a list and import the posts for the given section
  # if they're sub-threads, makes them into whole posts with the sub-thread's name
  def process_ordered(links, section_active, board_id, board_section, threaded=false, rename_prefix=nil)
    # rename_prefix only works if threaded is true
    links.map do |link|
      break if section_active && link == links.last

      url = link.at_css('a').attribute('href').value
      title_obj = link.at_css('> a') || link.children[0]
      title = title_obj.content.strip

      # special-case if a post has sub-threads
      if (sub_list = link.at_css('ul, ol'))
        sub_links = sub_list.css('> li')
        # import sub-threads with #{post_title}: before their title
        threads = process_ordered(sub_links, section_active, board_id, board_section, true, title + ': ')
        next
      end

      title = title[0..-2] if (is_active = link.content.strip.last == '+')
      post_status = is_active ? Post::STATUS_ACTIVE : Post::STATUS_COMPLETE

      desired_title = nil
      desired_title = rename_prefix.to_s + title if threaded

      scraper = PostScraper.new(url, board_id, board_section.id, post_status, threaded, false, desired_title)
      begin
        post = scraper.scrape!
      rescue AlreadyImportedError
        next # allows safe restart of a failed section where some but not all posts succeeded
      end
      post
    end
  end

  # special-case repealing
  if section_title == 'repealing'
    # import the first ordered list into a single post, as the threads are short
    shorts = links.first.css('li')
    threads = shorts.map do |link|
      link.at_css('a').attribute('href').value
    end
    url = threads.first
    scraper = PostScraper.new(url, board_id, board_section.id, Post::STATUS_COMPLETE, true)
    post = scraper.scrape_threads!(threads)
    post.update_attribute(:subject, 'guest list')
    puts "Renamed thread to 'guest list'"

    # import the second ordered list separately
    longs = links.last.css('li')
    process_ordered(longs, section_active, board_id, board_section, true)
    next
  end

  # process the ordered list for the section
  threaded = list.name == 'ul'
  process_ordered(links, section_active, board_id, board_section, threaded)
end
