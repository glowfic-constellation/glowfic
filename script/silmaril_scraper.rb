#!/usr/bin/env ruby

def prompt(str)
    print(str + '? 2 Alicorn 12 (dev) 34 (prod) lintamande: ')
    STDIN.gets.chomp
end

def strip_content(content)
  return content unless content.ends_with?("</div>")
  index = content.index('edittime')
  content[0..index-13]
end

def make_missing_character(name)
  id = prompt("User for "+name)

  user = User.find_by_id(id)
  gallery = Gallery.create!(user: user, name: name)
  character = Character.create!(user: user, name: name, gallery: gallery, screenname: name)
  CharactersGallery.create(character_id: character.id, gallery_id: gallery.id)
end

def make_icon(url, user, keyword, character)
  url = 'http://v.dreamwidth.org'+url if url[0] == '/'
  icon = Icon.find_by_url(url)
  if url && !icon
    end_index = keyword.index("(").to_i - 1
    start_index = (keyword.index(':') || -1) + 1
    icon_title = keyword[start_index..end_index].strip
    icon_title = 'Default' if icon_title.blank? && keyword.include?("(Default)")
    if character
      gallery = character.galleries.first
      gallery.icons << Icon.create!(user: character.user, url: url, keyword: icon_title)
      icon = Icon.find_by_url(url)
    else
      icon = Icon.create!(user: user, url: url, keyword: icon_title)
    end
  end
  icon
end

lintamande_id = Rails.env.production? ? 34 : 12
COLLECTIONS={'lintamande'=>lintamande_id,'alicornucopia'=>2}
def make_character(name)
  character = nil
  user = nil

  if COLLECTIONS.keys.include?(name)
    user = User.find_by_id(COLLECTIONS[name])
  else
    character = Character.find_by_screenname(name)
    character = make_missing_character(name) unless character
    user = character.user
  end
  return [character, user]
end

def make_reply(name, url, content, post, time, icon_title, thread_id=nil)
  character, user = make_character(name)
  icon = make_icon(url, user, icon_title, character)

  reply = Reply.new(
    user: user, 
    character: character, 
    icon: icon, 
    post: post, 
    content: strip_content(content), 
    thread_id: thread_id,
    created_at: time, 
    updated_at: time)
  reply.skip_post_update = true
  reply.skip_notify = true
  reply.save!
  reply
end

def comments_from_doc(post, html_doc)
  reply = nil
  comments = html_doc.at_css('#comments').css('.comment-thread')
  comments.each_with_index do |comment, i|
    content = comment.at_css('.comment-content').inner_html
    icon_url = comment.at_css('.userpic img').try(:attribute, 'src').try(:value)
    icon_title = comment.at_css('.userpic img').try(:attribute, 'title').try(:value)
    username = comment.at_css('.comment-poster b').inner_html
    created_at = comment.at_css('.datetime').text
    reply = make_reply(username, icon_url, content, post, created_at, icon_title)
  end
  reply
end

def post_from_url(url, section, index, title, active=false)
  response = HTTParty.get(url)
  html_doc = Nokogiri::HTML(response.body)
  puts "Importing thread '#{title}'"

  poster = html_doc.at_css('.entry-poster b').inner_html
  post_url = html_doc.at_css('.entry .userpic img').try(:attribute, 'src').try(:value)
  post_title = html_doc.at_css('.entry .userpic img').try(:attribute, 'title').try(:value)
  created_at = html_doc.at_css('.entry .datetime').text
  main_content = html_doc.at_css('.entry-content').inner_html
  character, user = make_character(poster)

  post = Post.new
  post.character = character
  post.user = user
  post.last_user_id = user.id
  post.board_id = 18
  post.subject = title
  post.content = strip_content(main_content)
  post.created_at = post.updated_at = created_at
  post.section = section
  post.section_order = index
  post.status = active ? Post::STATUS_ACTIVE : Post::STATUS_COMPLETE

  icon = make_icon(post_url, post.user, post_title, character)
  post.icon = icon

  post.save!
  return post, html_doc
end

def import_flat_thread(url, section, index, title, active)
  url = url + (if url.include?('?') then '&view=flat' else '?view=flat' end)
  post, html_doc = post_from_url(url, section, index, title, active)

  reply = comments_from_doc(post, html_doc)
  unless (links = html_doc.at_css('.page-links')).nil?
    links.css('a').each do |link|
      url = link.attribute('href').value
      response = HTTParty.get(url)
      reply = comments_from_doc(post, Nokogiri::HTML(response.body))
    end
  end
  post.skip_edited = true
  post.last_user_id = reply.user_id
  post.last_reply_id = reply.id
  post.save
end

# first argument is only-process-this section number
section_number = ARGV[0].to_i
section_index = 0

# processes the Silmaril index
# https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet
response = HTTParty.get('http://alicornutopia.dreamwidth.org/31812.html')
html_doc = Nokogiri::HTML(response.body)
main_list = html_doc.css('.entry-content li').select { |d| d.children.reject { |v| v.content.blank? || v.content.strip == '∞'}.count > 1 }
main_list.each do |section|
  # skip empty nodes
  next if section.content.blank?

  # restrict to specified section if provided
  section_index += 1
  next if section_number > 0 && section_index != section_number

  # don't reprocess already processed sections
  # next if BoardSection.where(section_order: section_index).where(board_id: 11).exists?

  # Silmaril posts on Dreamwidth are all in italics except don't touch me
  section_title = section.at_css('i').try(:content)
  next unless section_title
  next unless section.css('a').detect { |l| !l.attribute('href').value.include?('vast-journey') }
  print section_title + "\n"

  # process sections with multiple posts
  links = section.children.css('li')
  section_active = true
  section_status = section_active ? 0 : 1
  board_section = BoardSection.where(board_id: 18).where(name: section_title).first || BoardSection.create!(board_id: 18, name: section_title, status: section_status)
  links.each_with_index do |link, index|
    url = link.at_css('a').attribute('href').value
    next if url.include?('vast-journey')

    title = link.content
    title = title[0..-2] if is_active = link.content.strip.last == '+'
    import_flat_thread(url, board_section, index, title.strip, is_active)
  end
end