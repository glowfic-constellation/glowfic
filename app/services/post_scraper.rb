class PostScraper < Object
  attr_reader :url

  def initialize(url, board_id: Board::ID_SANDBOX, section_id: nil, status: :complete, threaded: false, console: false, subject: nil)
    @board_id = board_id
    @section_id = section_id
    @status = status
    @console_import = console
    @threaded_import = threaded # boolean
    @subject = subject
    @url = clean_url(url)
  end

  def scrape!(threads=nil)
    html_doc = doc_from_url(@url)

    Post.transaction do
      import_post_from_doc(html_doc)
      if threads.present?
        threads.each { |thread| evaluate_links(doc_from_url(thread)) }
      else
        evaluate_links(html_doc)
      end
      finalize_post_data
    end
    GenerateFlatPostJob.perform_later(@post.id)
    @post
  end
  alias scrape_threads! scrape!

  private

  def evaluate_links(base_doc)
    import_replies_from_doc(base_doc)
    links = page_links(base_doc)
    links.each_with_index do |link, i|
      Resque.logger.debug "Scraping '#{@post.subject}': page #{i + 1}/#{links.count}"
      doc = doc_from_url(link)
      import_replies_from_doc(doc)
    end
  end

  def doc_from_url(url)
    # download URL, trying up to 3 times
    max_try = 3
    retried = 0

    begin
      sleep 0.25
      data = HTTParty.get(url).body
    rescue Net::OpenTimeout => e
      retried += 1
      base_message = "Failed to get #{url}: #{e.message}"
      if retried < max_try
        Resque.logger.debug base_message + "; retrying (tried #{retried} #{'time'.pluralize(retried)})"
        retry
      else
        Resque.logger.warn base_message
        raise
      end
    end

    Nokogiri::HTML(data)
  end

  def page_links(doc)
    return threaded_page_links(doc) if @threaded_import
    links = doc.at_css('.page-links')
    return [] if links.nil?
    links.css('a').map { |link| link.attribute('href').value }
  end

  def threaded_page_links(doc)
    # gets pages after the first page
    # does not work based on depths as sometimes mistakes over depth are made
    # during threading (two replies made on the same depth)
    comments = doc.at_css('#comments').css('.comment-thread')
    # 0..24 are in full on the first page
    # fetch 25..49, …, on the other pages
    links = []
    index = 25
    while index < comments.count
      first_reply_in_batch = comments[index]
      url = first_reply_in_batch.at_css('.comment-title').at_css('a').attribute('href').value
      links << clean_url(url)
      depth = find_comment_depth(first_reply_in_batch)

      # check for accidental comment at same depth, if so go mark it as a new page too
      next_comment = comments[index + 1]
      if next_comment && find_comment_depth(next_comment) == depth
        index += 1
      else
        index += 25
      end
    end
    links
  end

  def import_post_from_doc(doc)
    subject = @subject || doc.at_css('.entry .entry-title').text.strip
    Resque.logger.info "Importing thread '#{subject}'"

    @post = Post.new(board_id: @board_id, section_id: @section_id, subject: subject, status: @status, is_import: true)

    # detect already imported
    # skip if it's a threaded import, unless a subject was given manually
    if (subject || !@threaded_import) && (subj_post = Post.find_by(subject: subject, board_id: @board_id))
      raise AlreadyImportedError.new("This thread has already been imported", subj_post.id)
    end

    scraper = ReplyScraper.new(@post, console: @console_import)
    scraper.import(doc)
  end

  def import_replies_from_doc(doc)
    comments = doc.at_css('#comments').css('.comment-thread')
    comments = comments.first(25).compact if @threaded_import # can't do 25 on non-threaded because single page is 50 per

    comments.each do |comment|
      reply = @post.replies.new(skip_notify: true, skip_post_update: true, skip_regenerate: true, is_import: true)
      scraper = ReplyScraper.new(reply, console: @console_import)
      scraper.import(comment)
    end
  end

  def finalize_post_data
    last_reply = @post.replies.last
    @post.last_user_id = (last_reply || @post).user_id
    @post.last_reply_id = last_reply.id if last_reply
    @post.tagged_at = (last_reply || @post).created_at
    @post.authors_locked = true
    @post.save!
  end

  def clean_url(url)
    uri = URI(url)
    query = Rack::Utils.parse_query(uri.query)
    return url if check_query(query)
    query['style'] = 'site'
    query['view'] = 'flat' unless @threaded_import
    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end

  def check_query(query)
    # query parameters are good if both:
    # - style is site
    # - view is flat or this a threaded import
    return false unless query['view'] == 'flat' || @threaded_import
    query['style'] == 'site'
  end

  def find_comment_depth(comment)
    classes = comment[:class].split(' ')
    classes -= ['comment-thread', 'comment-depth-even', 'comment-depth-odd'] # remove other classes on comments
    depth = classes.first
    depth = classes.find { |name| name.match?(/comment-depth-\d+/) } if classes.size > 1 # just in case
    depth.split('-')[-1].to_i
  end
end

class AlreadyImportedError < RuntimeError
  attr_reader :post_id
  def initialize(msg, post_id)
    @post_id = post_id
    super(msg)
  end
end
