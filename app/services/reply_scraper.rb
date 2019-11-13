class ReplyScraper < Object
  BASE_ACCOUNTS = {
    'alicornucopia'      => 'Alicorn',
    'pythbox'            => 'Kappa',
    'lintamande'         => 'lintamande',
    'marrinikari'        => 'Marri',
    'peterxy'            => 'Pedro',
    'peterverse'         => 'Pedro',
    'curiousdiscoverer'  => 'CuriousDiscoverer',
    'aestrix'            => 'Aestrix',
    'unbitwise'          => 'Unbitwise',
    'erinflight'         => 'ErinFlight',
    'andaisq'            => 'andaisq',
    'rockeye-stonetoe'   => 'Rockeye',
    'rockeye_stonetoe'   => 'Rockeye',
    'maggie-of-the-owls' => 'MaggieoftheOwls',
    'maggie_of_the_owls' => 'MaggieoftheOwls', # have both - and _ versions cause Dreamwidth supports both
    'nemoconsequentiae'  => 'Nemo',
    'armokgob'           => 'Armok',
    'timepoof'           => 'Timepoof',
  }

  def initialize(reply, console: false)
    @reply = reply
    @console_import = console
  end

  def import(comment)
    if @reply.is_a?(Post)
      username = comment.at_css('.entry-poster b').inner_html
      img_url = comment.at_css('.entry .userpic img').try(:attribute, 'src').try(:value)
      img_keyword = comment.at_css('.entry .userpic img').try(:attribute, 'title').try(:value)
      created_at = comment.at_css('.entry .datetime').text
      content = comment.at_css('.entry-content').inner_html
    else
      content = comment.at_css('.comment-content').inner_html
      img_url = comment.at_css('.userpic img').try(:attribute, 'src').try(:value)
      img_keyword = comment.at_css('.userpic img').try(:attribute, 'title').try(:value)
      username = comment.at_css('.comment-poster b').inner_html
      created_at = comment.at_css('.datetime').text
    end

    @reply.content = strip_content(content)
    @reply.editor_mode = 'html'
    @reply.created_at = @reply.updated_at = created_at

    set_from_username(@reply, username)
    set_from_icon(@reply, img_url, img_keyword) if img_url

    if @reply.is_a?(Post)
      @reply.last_user_id = @reply.user_id
      @reply.edited_at = created_at
    end

    Audited.audit_class.as_user(@reply.user) do
      @reply.save!
    end
  end

  def set_from_username(tag, username)
    return User.find_by(username: BASE_ACCOUNTS[username]) if BASE_ACCOUNTS.key?(username)

    unless (character = Character.find_by(screenname: [username.tr("-", "_"), username.tr("_", "-")]))
      user = prompt_for_user(username)
      character = Character.create!(user: user, name: username, screenname: username)
      gallery = Gallery.create!(user: user, name: username)
      CharactersGallery.create!(character_id: character.id, gallery_id: gallery.id)
    end

    tag.character = character
    character.user
  end

  def prompt_for_user(username)
    raise UnrecognizedUsernameError.new("Unrecognized username: #{username}") unless @console_import
    print("User ID or username for #{username}? ")
    input = STDIN.gets.chomp
    return User.find_by(id: input) if input.to_s == input.to_i.to_s
    User.find_by('lower(username) = ?', input.downcase)
  end

  def set_from_icon(tag, url, keyword)
    url = parse_url(url)
    icon = Icon.find_by(url: url)
    return icon if icon

    keyword = parse_keyword(keyword)

    if tag.character
      icon = tag.character.icons.find_by(keyword: keyword)
      icon ||= clean_keyword(tag, keyword)
      return icon if icon
    end

    create_icon(tag, url, keyword)
  end

  def parse_url(url)
    url = 'https://v.dreamwidth.org' + url if url[0] == '/'
    host_url = url.gsub(/https?:\/\//, "")
    'https://' + host_url
  end

  def parse_keyword(keyword)
    end_index = keyword.index("(Default)").to_i - 1
    start_index = (keyword.index(':') || -1) + 1
    parsed_keyword = keyword[start_index..end_index].strip
    parsed_keyword = 'Default' if parsed_keyword.blank? && keyword.include?("(Default)")
    parsed_keyword
  end

  def clean_keyword(tag, keyword)
    # split out the last " (...)" from the keyword (which should be at the
    # very end), if applicable, for without_desc
    without_desc = nil
    if keyword.end_with?(')')
      lbracket = keyword.rindex(' (')
      if lbracket && lbracket > 0 # without_desc must be non-empty
        without_desc = keyword[0...lbracket]
        icon = tag.character.icons.find_by(keyword: without_desc)
      end
    end
    icon ||= kappa_keyword(tag, keyword, without_desc)
    icon
  end

  def kappa_keyword(tag, keyword, without_desc)
    # kappa icon handling - icons are prefixed
    if tag.user_id == 3 && (spaceindex = keyword.index(" "))
      unprefixed = keyword[spaceindex..-1]
      icon = tag.character.icons.detect { |i| i.keyword.ends_with?(unprefixed) }
      icon ||= tag.character.icons.detect { |i| i.keyword.ends_with?(without_desc[spaceindex..-1]) } if without_desc
    end
    icon
  end

  def create_icon(tag, https_url, keyword)
    icon = Icon.create!(user: tag.user, url: https_url, keyword: keyword)
    return icon unless tag.character

    gallery = tag.character.galleries.first
    if gallery.nil?
      gallery = Gallery.create!(user: tag.user, name: tag.character.name)
      CharactersGallery.create!(character_id: tag.character.id, gallery_id: gallery.id)
    end
    gallery.icons << icon
    icon
  end

  def strip_content(content)
    return content unless content.ends_with?("</div>")
    index = content.index('edittime')
    content[0..(index - 13)]
  end
end

class UnrecognizedUsernameError < RuntimeError
end
