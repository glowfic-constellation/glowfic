module PostHelper
  def author_links(post, linked: true, colored: false)
    total = post.authors.size
    authors = post.authors.reject(&:deleted?).sort_by{|a| a.username.downcase}
    num_deleted = total - authors.size
    deleted = 'deleted user'.pluralize(num_deleted)
    return "(#{deleted})" if authors.empty?

    if total < 4
      links = authors.map { |author| linked ? user_link(author, colored: colored) : author.username }
      joined_links = safe_join(links, ', ')
      return joined_links if num_deleted.zero?
      return safe_join([joined_links, "#{num_deleted} #{deleted}"], ' and ')
    end

    first_author = post.user.deleted? ? authors.first : post.user
    first_link = linked ? user_link(first_author, colored: colored) : first_author.username
    hovertext = safe_join((authors - [first_author]).map(&:username), ', ')
    others = linked ? link_to("#{total-1} others", stats_post_path(post), title: hovertext) : "#{total-1} others"
    safe_join([first_link, others], ' and ')
  end

  def allowed_boards(obj, user)
    authored_ids = BoardAuthor.where(user: user).select(:board_id)
    Board.where(id: obj.board_id).or(Board.where(authors_locked: false)).or(Board.where(id: authored_ids)).ordered
  end
end
