module WritableHelper
  def unread_warning
    return unless @replies.present?
    return if @replies.total_pages == page
    'You are not on the latest page of the post ' + \
    tag.a('(View unread)', href: unread_path(@post), class: 'unread-warning') + ' ' + \
    tag.a('(New tab)', href: unread_path(@post), class: 'unread-warning', target: '_blank')
  end

  def post_or_reply_link(reply)
    return unless reply.id.present?
    post_or_reply_mem_link(id: reply.id, klass: reply.class)
  end

  def post_or_reply_mem_link(id: nil, klass: nil)
    return if id.nil?
    if klass == Reply
      reply_path(id, anchor: "reply-#{id}")
    else
      post_path(id)
    end
  end

  def has_edit_audits?(audits, written)
    return false unless written.id.present?
    if written.is_a?(Post)
      count = audits.fetch(:post, 0)
    else
      count = audits.fetch(written.id, 0)
    end
    count > 1
  end

  # modified version of split_paragraphs that doesn't mangle large breaks
  # https://apidock.com/rails/v4.2.7/ActionView/Helpers/TextHelper/split_paragraphs
  def split_paragraphs_largebreak(text)
    return [] if text.blank?
    text.to_str.gsub(/\r\n?/, "\n").split("\n\n").map! do |t|
      t.gsub!(/(^\n|[^\n]\n)(?=[^\n])/, '\1<br />') || t
    end
  end

  # modified version of simple_format that doesn't mangle large breaks
  # https://apidock.com/rails/ActionView/Helpers/TextHelper/simple_format
  def simple_format_largebreak(text, options={})
    wrapper_tag = options.fetch(:wrapper_tag, :p)
    text = sanitize(text) if options.fetch(:sanitize, true)
    paragraphs = split_paragraphs_largebreak(text)

    if paragraphs.empty?
      content_tag(wrapper_tag, nil)
    else
      paragraphs.map! do |paragraph|
        if paragraph.empty?
          content_tag(wrapper_tag, '&nbsp;'.html_safe)
        else
          content_tag(wrapper_tag, raw(paragraph))
        end
      end.join("\n\n").html_safe
    end
  end

  P_TAG = /<p( [^>]*)?>/
  BR_TAG = /<br *\/?>/
  BLOCKQUOTE_QUICK_SEARCH = '<blockquote'.freeze
  BLOCKQUOTE_TAG = /<blockquote( |>)/
  LINEBREAK = /\r?\n/
  BR = '<br>'.freeze

  # specific blockquote handling is due to simple_format wanting to wrap a blockquote in a paragraph
  def sanitize_written_content(content)
    unless content[P_TAG] || content[BR_TAG]
      content = if content[BLOCKQUOTE_QUICK_SEARCH] && content[BLOCKQUOTE_TAG]
        content.gsub(LINEBREAK, BR)
      else
        simple_format_largebreak(content, sanitize: false)
      end
    end

    Glowfic::Sanitizers.written(content)
  end
end
