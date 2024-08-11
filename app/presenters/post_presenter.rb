# frozen_string_literal: true
class PostPresenter
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def as_json(options={})
    return min_json(post) if options[:min]
    return includeless_json(post) unless options[:include]
    included_json(post, options[:include])
  end

  private

  def min_json(post)
    post.as_json_without_presenter(only: [:id, :subject])
  end

  def includeless_json(post)
    attrs = %w(id subject description created_at tagged_at status section_order)
    post_json = post.as_json_without_presenter(only: attrs)
    post_json.merge({
      board: post.board,
      section: post.section,
      authors: post.joined_authors.ordered,
      num_replies: post.reply_count,
    })
  end

  def included_json(post, includes)
    post_json = includeless_json(post)
    post_json[:content] = post.content if includes.include?(:content)
    post_json[:character] = character(post) if includes.include?(:character)
    post_json[:icon] = icon(post) if includes.include?(:icon)
    post_json
  end

  def character(post)
    return unless post.character_id
    {
      id: post.character_id,
      name: post.name,
      screenname: post.screenname,
    }
  end

  def icon(post)
    return unless post.icon_id
    {
      id: post.icon_id,
      url: post.url,
      keyword: post.keyword,
    }
  end
end
