#!/usr/bin/env ruby

def prompt(str)
    print(str + '? ')
    STDIN.gets.chomp
end

def strip_content(content)
  return content unless content.ends_with?("</div>")
  index = content.index('edittime')
  content[0..index-13]
end

def make_missing_character(name)
  id = prompt("User for "+name)

  user = User.where('lower(username) = ?', id).first || User.where(id: id).first
  gallery = Gallery.create!(user: user, name: name)
  character = Character.create!(user: user, name: name, screenname: name)
  CharactersGallery.create(character_id: character.id, gallery_id: gallery.id)
  character
end

def make_icon(url, user, keyword, character)
  url = 'https://v.dreamwidth.org'+url if url[0] == '/'
  host_url = url.gsub(/https?:\/\//, "")
  http_url = 'http://' + host_url
  https_url = 'https://' + host_url
  icon = Icon.find_by_url(http_url) || Icon.find_by_url(https_url)
  if url && !icon
    end_index = keyword.index("(Default)").to_i - 1
    start_index = (keyword.index(':') || -1) + 1
    icon_title = keyword[start_index..end_index].strip
    icon_title = 'Default' if icon_title.blank? && keyword.include?("(Default)")
    debugger unless icon_title.present?
    if character
      gallery = character.galleries.first
      if gallery.nil?
        gallery = Gallery.create!(user: user, name: character.name)
        CharactersGallery.create(character_id: character.id, gallery_id: gallery.id)
      end
      gallery.icons << Icon.create!(user: character.user, url: url, keyword: icon_title)
      icon = Icon.find_by_url(url)
    else
      icon = Icon.create!(user: user, url: url, keyword: icon_title)
    end
  end
  icon
end

lintamande_id = User.where('lower(username) = ?', 'lintamande').first.id
pedro_id = User.where('lower(username) = ?', 'pedro').first.id
alicorn_id = User.where('lower(username) = ?', 'alicorn').first.id
kappa_id = User.where('lower(username) = ?', 'kappa').first.id
COLLECTIONS={'lintamande'=>lintamande_id,'alicornucopia'=>alicorn_id, 'pythbox'=>kappa_id, 'peterxy'=>pedro_id, 'peterverse'=>pedro_id}
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

def post_from_url(url, title, active=false)
  response = HTTParty.get(url)
  html_doc = Nokogiri::HTML(response.body)
  post_title = html_doc.at_css('.entry .entry-title').text.strip
  puts "Importing thread '#{post_title}'"

  poster = html_doc.at_css('.entry-poster b').inner_html
  post_url = html_doc.at_css('.entry .userpic img').try(:attribute, 'src').try(:value)
  img_title = html_doc.at_css('.entry .userpic img').try(:attribute, 'title').try(:value)
  created_at = html_doc.at_css('.entry .datetime').text
  main_content = html_doc.at_css('.entry-content').inner_html
  character, user = make_character(poster)

  post = Post.new
  post.character = character
  post.user = user
  post.last_user_id = user.id
  post.board_id = Rails.env.production? ? 3 : 5
  post.subject = post_title
  post.content = strip_content(main_content)
  post.created_at = post.updated_at = created_at
  post.status = active ? Post::STATUS_ACTIVE : Post::STATUS_COMPLETE

  icon = make_icon(post_url, post.user, img_title, character)
  post.icon = icon

  post.save!
  return post, html_doc
end

def import_flat_thread(url, title, active, old_post)
  url = url + (if url.include?('?') then '&view=flat' else '?view=flat' end) unless url.include?('view=flat')
  url = url + '&style=site' unless url.include?('style=site')
  post, html_doc = if old_post
                     puts "Re-importing thread '#{title}'"
                     [old_post, Nokogiri::HTML(HTTParty.get(url).body)]
                   else
                     post_from_url(url, title, active)
                   end

  reply = comments_from_doc(post, html_doc) unless old_post
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
  post.tagged_at = reply.created_at
  post.save
end

# first argument is only-process-this section number
section_number = ARGV[0].to_i
section_index = 0

# processes Pedro's personal index
# https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet
response = HTTParty.get('https://peterverse.dreamwidth.org/1643.html')
html_doc = Nokogiri::HTML(response.body)
main_list = html_doc.css('.entry-content li').select { |d| d.children.reject { |v| v.content.blank? || v.content.strip == '∞'}.count > 0 }
main_list.each do |section|
  # skip empty nodes
  next if section.content.blank?

  section_title = section.children.first.content.strip
  next unless section_title
  url = section.at_css('a').attribute('href').value
  next if url.include?('vast-journey')
  next if url == 'http://glowfic.dreamwidth.org/36602.html?view=flat' # Requested to skip Unbitwise

  # Skip already imported
  old_post = Post.where(subject: section_title).first
  next if old_post && old_post.replies.count != 25

  # restrict to specified section if provided
  section_index += 1
  next if section_number > 0 && section_index != section_number
  next if [34, 35].include?(section_number) # Skip Kappa's for now because of duplicate icons

  # import thread transactionally
  Post.transaction do
    import_flat_thread(url, section_title, true, old_post)
  end
end
