#!/usr/bin/env ruby

def prompt(str)
    print(str + '? 2 Alicorn 3 Kappa: ')
    gets.strip
end

def make_missing_character(name)
  user = User.find_by_id(prompt("User for "+name))
  gallery = Gallery.create!(user: user, name: name)
  character = Character.create!(user: user, name: name, gallery: gallery, screenname: name)
end

def make_reply(name, url, content, post, time, icon_title)
  character = Character.find_by_screenname(name)
  character = make_missing_character(name) unless character

  icon = Icon.find_by_url(url)
  if url && !icon
    character.gallery.icons << Icon.create!(user: character.user, url: url, keyword: icon_title)
    icon = Icon.find_by_url(url)
  end

  Reply.create!(user: character.user, character: character, icon: icon, post: post, content: content, created_at: time, updated_at: time)
end

def comments_from_doc(post, html_doc)
  comments = html_doc.at_css('#comments').css('.comment-thread')
  comments.each_with_index do |comment, i|
    content = comment.at_css('.comment-content').inner_html
    icon_url = comment.at_css('.userpic img').try(:attribute, 'src').try(:value)
    icon_title = comment.at_css('.userpic img').try(:attribute, 'title').try(:value)
    username = comment.at_css('.comment-poster b').inner_html
    created_at = comment.at_css('.datetime').text
    make_reply(username, icon_url, content, post, created_at, icon_title)
  end
end

# https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet
response = HTTParty.get('http://edgeofyourseat.dreamwidth.org/2121.html?style=site')
html_doc = Nokogiri::HTML(response.body)
links = html_doc.css('.entry-content li a')
links.each_with_index do |link, i|
  next if i < 481
  url = link.attribute('href').value
  next if url.include?('#cmt') or url.include?('thread=')
  url = url + (if url.include?('?') then '&view=flat' else '?view=flat' end)

  response = HTTParty.get(url)
  html_doc = Nokogiri::HTML(response.body)

  title = html_doc.at_css('.entry-title a').inner_html
  puts "Importing thread '#{title}' #{i}"
  poster = html_doc.at_css('.entry-poster b').inner_html
  post_url = html_doc.at_css('.entry .userpic img').try(:attribute, 'src').try(:value)
  created_at = html_doc.at_css('.entry .datetime').text
  main_content = html_doc.at_css('.entry-content').inner_html

  post = Post.new
  character = Character.find_by_screenname(poster)
  character = make_missing_character(poster) unless character
  post.character = character
  post.user = character.user
  post.board = Board.find(1)
  post.subject = title
  post.content = main_content
  post.created_at = post.updated_at = created_at

  icon = Icon.find_by_url(post_url)
  if post_url && !icon
    post_title = html_doc.at_css('.entry .userpic img').try(:attribute, 'title').try(:value)
    character.gallery.icons << Icon.create!(user: character.user, url: post_url, keyword: post_title)
    icon = Icon.find_by_url(post_url)
  end
  post.icon = icon

  post.save!

  comments_from_doc(post, html_doc)
  unless (links = html_doc.at_css('.page-links')).nil?
    links.css('a').each do |link|
      url = link.attribute('href').value
      response = HTTParty.get(url)
      comments_from_doc(post, Nokogiri::HTML(response.body))
    end
  end
  break
end
