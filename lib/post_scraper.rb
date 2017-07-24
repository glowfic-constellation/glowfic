class PostScraper < Object
  SANDBOX_ID = Rails.env.production? ? 3 : 5
  BASE_ACCOUNTS = {
    'alicornucopia' => 'Alicorn',
    'pythbox' => 'Kappa',
    'lintamande' => 'lintamande',
    'marrinikari' => 'Marri',
    'peterxy' => 'Pedro',
    'peterverse' => 'Pedro',
    'curiousdiscoverer' => 'CuriousDiscoverer',
    'aestrix' => 'Aestrix',
    'unbitwise' => 'Unbitwise',
    'erinflight' => 'ErinFlight',
    'maggie-of-the-owls' => 'MaggieoftheOwls',
    'maggie_of_the_owls' => 'MaggieoftheOwls' # have both - and _ versions cause Dreamwidth supports both
  }

  attr_reader :url

  def initialize(url, board_id=nil, section_id=nil, status=nil, threaded_import=false, console_import=false)
    @board_id = board_id || SANDBOX_ID
    @section_id = section_id
    @status = status || Post::STATUS_COMPLETE
    url = url + (if url.include?('?') then '&view=flat' else '?view=flat' end) unless url.include?('view=flat')
    url = url + '&style=site' unless url.include?('style=site')
    @url = url
    @console_import = console_import
    @threaded_import = threaded_import
  end

  def scrape!
    @html_doc = doc_from_url(@url)

    Post.transaction do
      import_post_from_doc(@html_doc)
      import_replies_from_doc(@html_doc)
      page_links.each do |link|
        doc = doc_from_url(link)
        import_replies_from_doc(doc)
      end
      finalize_post_data
    end
    Resque.enqueue(GenerateFlatPostJob, @post.id)
    @post
  end

  private

  def doc_from_url(url)
    Nokogiri::HTML(HTTParty.get(url).body)
  end

  def page_links
    return threaded_page_links if @threaded_import
    links = @html_doc.at_css('.page-links')
    return [] if links.nil?
    links.css('a').map { |link| link.attribute('href').value }
  end

  def threaded_page_links
    last_index = @html_doc.at_css('#comments').css('.comment-thread').last.attribute('class').value.split.last.gsub("comment-depth-", "").to_i
    index = 26
    links = []
    while true
      next_reply = @html_doc.at_css(".comment-depth-#{index}")
      return links unless next_reply.present?
      links << next_reply.at_css('.comment-title').at_css('a').attribute('href').value
      index += 25
    end
  end

  def import_post_from_doc(doc)
    subject = doc.at_css('.entry .entry-title').text.strip
    puts "Importing thread '#{subject}'"

    username = doc.at_css('.entry-poster b').inner_html
    img_url = doc.at_css('.entry .userpic img').try(:attribute, 'src').try(:value)
    img_keyword = doc.at_css('.entry .userpic img').try(:attribute, 'title').try(:value)
    created_at = doc.at_css('.entry .datetime').text
    content = doc.at_css('.entry-content').inner_html

    @post = Post.new
    @post.board_id = @board_id
    @post.section_id = @section_id
    @post.subject = subject
    @post.content = strip_content(content)
    @post.created_at = @post.updated_at = @post.edited_at = created_at
    @post.status = @status
    @post.is_import = true

    # detect already imported
    if !@threaded_import && (subj_post = Post.where(subject: @post.subject).first)
      raise AlreadyImportedError.new("This thread has already been imported", subj_post.id)
    end

    set_from_username(@post, username)
    @post.last_user_id = @post.user_id

    set_from_icon(@post, img_url, img_keyword)

    @post.save!
  end

  def import_replies_from_doc(doc)
    comments = if @threaded_import
      doc.at_css('#comments').css('.comment-thread').first(25).compact
    else
      doc.at_css('#comments').css('.comment-thread') # can't do 25 on non-threaded because single page is 50 per
    end

    comments.each do |comment|
      content = comment.at_css('.comment-content').inner_html
      img_url = comment.at_css('.userpic img').try(:attribute, 'src').try(:value)
      img_keyword = comment.at_css('.userpic img').try(:attribute, 'title').try(:value)
      username = comment.at_css('.comment-poster b').inner_html
      created_at = comment.at_css('.datetime').text

      @reply = Reply.new
      @reply.post = @post
      @reply.content = strip_content(content)
      @reply.created_at = @reply.updated_at = created_at

      set_from_username(@reply, username)
      set_from_icon(@reply, img_url, img_keyword)

      @reply.skip_notify = true
      @reply.skip_post_update = true
      @reply.skip_regenerate = true
      @reply.is_import = true
      @reply.save!
    end
  end

  def finalize_post_data
    @post.last_user_id = @reply.try(:user_id) || @post.user_id
    @post.last_reply_id = @reply.try(:id)
    @post.tagged_at = @reply.try(:created_at) || @post.created_at
    @post.save!
  end

  def set_from_username(tag, username)
    if BASE_ACCOUNTS.keys.include?(username)
      tag.user = User.find_by(username: BASE_ACCOUNTS[username])
      return
    end

    unless (character = Character.find_by(screenname: username))
      user = prompt_for_user(username)
      character = Character.create!(user: user, name: username, screenname: username)
      gallery = Gallery.create!(user: user, name: username)
      CharactersGallery.create!(character_id: character.id, gallery_id: gallery.id)
    end

    tag.character = character
    tag.user = character.user
  end

  def prompt_for_user(username)
    raise UnrecognizedUsernameError.new("Unrecognized username: #{username}") unless @console_import
    print('User ID or username for ' + username + '? ')
    input = STDIN.gets.chomp
    return User.find_by_id(input) if input.to_s == input.to_i.to_s
    User.where('lower(username) = ?', input.downcase).first
  end

  def set_from_icon(tag, url, keyword)
    return unless url

    url = 'https://v.dreamwidth.org' + url if url[0] == '/'
    host_url = url.gsub(/https?:\/\//, "")
    https_url = 'https://' + host_url
    icon = Icon.find_by(url: https_url)
    tag.icon = icon and return if icon

    end_index = keyword.index("(Default)").to_i - 1
    start_index = (keyword.index(':') || -1) + 1
    parsed_keyword = keyword[start_index..end_index].strip
    parsed_keyword = 'Default' if parsed_keyword.blank? && keyword.include?("(Default)")
    keyword = parsed_keyword

    if tag.character
      icon = tag.character.icons.where(keyword: keyword).first
      tag.icon = icon and return if icon

      # kappa icon handling - icons are prefixed
      if tag.user_id == 3 && (spaceindex = keyword.index(" "))
        unprefixed = keyword.slice(spaceindex, keyword.length)
        icon = tag.character.icons.detect { |i| i.keyword.ends_with?(unprefixed) }
        tag.icon = icon and return if icon
      end
    end

    icon = Icon.create!(user: tag.user, url: https_url, keyword: keyword)
    tag.icon = icon
    return unless tag.character

    gallery = tag.character.galleries.first
    if gallery.nil?
      gallery = Gallery.create!(user: tag.user, name: tag.character.name)
      CharactersGallery.create!(character_id: tag.character.id, gallery_id: gallery.id)
    end
    gallery.icons << icon
  end

  def strip_content(content)
    return content unless content.ends_with?("</div>")
    index = content.index('edittime')
    content[0..index-13]
  end
end

class UnrecognizedUsernameError < Exception
end

class AlreadyImportedError < Exception
  attr_reader :post_id
  def initialize(msg, post_id)
    @post_id = post_id
    super(msg)
  end
end
