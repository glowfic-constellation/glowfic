xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/' do
  xml.channel do
    xml.title @post.subject
    xml.link post_url(@post)
    xml.atom :link, href: post_url(@post, format: :rss), rel: 'self', type: 'application/rss+xml'
    xml.description strip_tags(@post.description.presence || @post.subject)
    xml.language 'en-us'
    xml.lastBuildDate @post.tagged_at.rfc822 if @post.tagged_at

    @feed_items.each do |item|
      xml.item do
        if item.is_a?(Post)
          permalink = post_url(item)
          xml.title item.subject
        else
          permalink = reply_url(item, anchor: "reply-#{item.id}")
          xml.title(item.name.presence || item.username)
        end
        xml.link permalink
        xml.guid permalink, isPermaLink: 'true'
        xml.tag! 'dc:creator', item.username
        xml.pubDate item.created_at.rfc822 if item.created_at
        xml.description do
          xml.cdata! sanitize_written_content(item.content.to_s, item.editor_mode)
        end
      end
    end
  end
end
