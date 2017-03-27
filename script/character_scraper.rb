#!/usr/bin/env ruby

comm_name = ARGV[0]
user_id = ARGV[1]

unless comm_name.present? && user_id.present?
  puts "Usage: character_scraper.rb [community url] [user id]"
  exit 0
end

unless user = User.find_by_id(user_id)
  puts "That user does not exist"
  exit 0
end

puts "Importing #{user.username} characters from the #{comm_name} community"

response = HTTParty.get("http://#{comm_name}.dreamwidth.org/profile")
html_doc = Nokogiri::HTML(response.body)
characters = html_doc.at_css('#members_people_body').css('a').map(&:content).map(&:strip)
characters.each do |username|
  puts "  -" + username
  url_name = username.gsub('_', '-')
  response = HTTParty.get("http://#{url_name}.dreamwidth.org/profile")
  html_doc = Nokogiri::HTML(response.body)
  name = html_doc.at_css('#basics_body .profile td').content.strip

  unless gallery = Gallery.where(name: username).first
    gallery = Gallery.create!(user: user, name: username)
  end

  unless character = Character.where(screenname: username).first
    character = Character.create!(user: user, name: name, screenname: username)
  end

  unless CharactersGallery.where(gallery_id: gallery.id, character_id: character.id).exists?
    CharactersGallery.create(character_id: character.id, gallery_id: gallery.id)
  end

  response = HTTParty.get("http://#{url_name}.dreamwidth.org/icons")
  html_doc = Nokogiri::HTML(response.body)
  icons = html_doc.css('.icon-container .icon')
  icons.each do |icon|
    image = icon.at_css('.icon-image img')
    image_url = image.attribute('src').value.strip
    image_keyword = image.attribute('title').value.strip
    icon = Icon.where(url: image_url).first
    if icon.nil?
      gallery.icons << Icon.create!(user: user, url: image_url, keyword: image_keyword)
    elsif !icon.galleries.include?(gallery)
      gallery.icons << icon
    end
  end
end
