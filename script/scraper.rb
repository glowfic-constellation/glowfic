#!/usr/bin/env ruby

def prompt(str)
    print(str + '? 2 Alicorn 3 Kappa: ')
    gets.strip
end

def strip_content(content)
  return content unless content.ends_with?("</div>")
  index = content.index('edittime')
  content[0..index-13]
end

def make_missing_character(name, ac, kc)
  id = if ac.include?(name)
    2
  elsif kc.include?(name)
    3
  else
    prompt("User for "+name)
  end

  user = User.find_by_id(id)
  gallery = Gallery.create!(user: user, name: name)
  character = Character.create!(user: user, name: name, gallery: gallery, screenname: name)
end

def make_icon(url, user, keyword, character)
  url = 'http://v.dreamwidth.org'+url if url[0] == '/'
  icon = Icon.find_by_url(url)
  if url && !icon
    end_index = keyword.index("(").to_i - 1
    start_index = (keyword.index(':') || -1) + 1
    icon_title = keyword[start_index..end_index].strip
    icon_title = 'Default' if icon_title.blank? && keyword.include?("(Default)")
    debugger if icon_title.blank?
    if character
      character.gallery.icons << Icon.create!(user: character.user, url: url, keyword: icon_title)
      icon = Icon.find_by_url(url)
    else
      icon = Icon.create!(user: user, url: url, keyword: icon_title)
    end
  end
  icon
end

COLLECTIONS={'pythbox'=>3,'alicornucopia'=>2}
def make_character(name, ac, kc)
  character = nil
  user = nil

  if COLLECTIONS.keys.include?(name)
    user = User.find_by_id(COLLECTIONS[name])
  else
    character = Character.find_by_screenname(name)
    character = make_missing_character(name, ac, kc) unless character
    user = character.user
  end
  return [character, user]
end

def make_reply(name, url, content, post, time, icon_title, ac, kc, thread_id=nil)
  character, user = make_character(name, ac, kc)
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
  reply.save!
  reply
end

def comments_from_doc(post, html_doc, ac, kc)
  comments = html_doc.at_css('#comments').css('.comment-thread')
  comments.each_with_index do |comment, i|
    content = comment.at_css('.comment-content').inner_html
    icon_url = comment.at_css('.userpic img').try(:attribute, 'src').try(:value)
    icon_title = comment.at_css('.userpic img').try(:attribute, 'title').try(:value)
    username = comment.at_css('.comment-poster b').inner_html
    created_at = comment.at_css('.datetime').text
    make_reply(username, icon_url, content, post, created_at, icon_title, ac, kc)
  end
end

def post_from_url(url, section, index, title, ac, kc, active=false)
  response = HTTParty.get(url)
  html_doc = Nokogiri::HTML(response.body)
  puts "Importing thread '#{title}'"

  poster = html_doc.at_css('.entry-poster b').inner_html
  post_url = html_doc.at_css('.entry .userpic img').try(:attribute, 'src').try(:value)
  post_title = html_doc.at_css('.entry .userpic img').try(:attribute, 'title').try(:value)
  created_at = html_doc.at_css('.entry .datetime').text
  main_content = html_doc.at_css('.entry-content').inner_html
  character, user = make_character(poster, ac, kc)

  post = Post.new
  post.character = character
  post.user = user
  post.board = Board.find(1)
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

def import_subthread(sublink, post, ac, kc, thread_id=nil)
  subthread = sublink.at_css('a')
  suburl = subthread.attribute('href').value

  response = HTTParty.get(suburl)
  html_doc = Nokogiri::HTML(response.body)
  comments = html_doc.at_css('#comments').css('.comment-thread')

  last_comment = nil
  comments.each_with_index do |comment, i|
    if i == 25
      last_comment = comment.at_css('.comment-title')
      break
    end
    content = comment.at_css('.comment-content').inner_html
    icon_url = comment.at_css('.userpic img').try(:attribute, 'src').try(:value)
    icon_title = comment.at_css('.userpic img').try(:attribute, 'title').try(:value)
    username = comment.at_css('.comment-poster b').inner_html
    created_at = comment.at_css('.datetime').text
    reply = make_reply(username, icon_url, content, post, created_at, icon_title, ac, kc, thread_id)
    unless thread_id
      thread_id = reply.id
      reply.thread_id = thread_id
      reply.skip_post_update = true
      reply.save!
    end
  end
  import_subthread(last_comment, post, ac, kc, thread_id) if last_comment
end

def import_threaded_thread(url, section, index, link, ac, kc)
  url = url + (if url.include?('?') then '&view=threaded' else '?view=threaded' end)
  title = link.children[0].content + ' ' + link.children[1].content
  post, doc = post_from_url(url, section, index, title, ac, kc)

  list_of_subthreads = link.children.last
  css_class = list_of_subthreads.name == 'ul' ? 'li' : 'ul li'
  subthreads = list_of_subthreads.css(css_class)
  subthreads.each do |subthread|
    puts "  -" + subthread.at_css('a').content
    import_subthread(subthread, post, ac, kc, nil)
  end
end

def import_flat_thread(url, section, index, title, ac, kc, active)
  url = url + (if url.include?('?') then '&view=flat' else '?view=flat' end)
  post, html_doc = post_from_url(url, section, index, title, ac, kc, active)

  comments_from_doc(post, html_doc, ac, kc)
  unless (links = html_doc.at_css('.page-links')).nil?
    links.css('a').each do |link|
      url = link.attribute('href').value
      response = HTTParty.get(url)
      comments_from_doc(post, Nokogiri::HTML(response.body), ac, kc)
    end
  end
end

alicorn_characters = []
kappa_characters = []

# get Alicorn characters
response = HTTParty.get('http://belltower.dreamwidth.org/profile')
html_doc = Nokogiri::HTML(response.body)
alicorn_characters = html_doc.at_css('#members_people_body').css('a').map(&:content)

# get Kappa characters
response = HTTParty.get('http://binary-heat.dreamwidth.org/profile')
html_doc = Nokogiri::HTML(response.body)
kappa_characters = html_doc.at_css('#members_people_body').css('a').map(&:content)

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
  next if BoardSection.where(section_order: section_index).exists?

  # don't crash on final empty section
  section_title = section.children[0].content.strip
  next unless section_title.present?

  # process sections that are exclusively a single post with multiple threads
  if section.children[1].name == 'a'
    link = section.children[1]
    url = link.attribute('href').value
    section_title = link.inner_html
    board_section = BoardSection.create!(board_id: 1, name: section_title, section_order: section_index, status: 1)
    import_threaded_thread(url, board_section, 0, section, alicorn_characters, kappa_characters)
    next
  end

  # process sections with multiple posts
  links = section.children[1].css('li')
  section_active = links.last.children.size == 1 && links.last.children.first.name == 'text' && links.last.children.first.content.strip == '+'
  section_status = section_active ? 0 : 1
  board_section = BoardSection.create!(board_id: 1, name: section_title, section_order: section_index, status: section_status)
  links.each_with_index do |link, index|
    break if section_active && link == links.last

    url = link.at_css('a').attribute('href').value
    next if url.include?('#cmt') or url.include?('thread=')

    if link.children.last.name == 'ul'
      import_threaded_thread(url, board_section, index, link, alicorn_characters, kappa_characters)
    else
      title = link.content
      title = title[0..-2] if is_active = link.content.strip.last == '+'
      import_flat_thread(url, board_section, index, title.strip, alicorn_characters, kappa_characters, is_active)
    end
  end
end