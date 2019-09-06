class Post::Displayer < Generic::Service
  attr_reader :unread, :paginate_params, :cur_page

  def initialize(post, user:, per:, cur_page:)
    @post = post
    @replies = @post.replies
    @user = user
    @per = per
    @cur_page = cur_page
    super()
  end

  def find_page(params)
    @paginate_params = {controller: 'posts', action: 'show', id: @post.id}
    if params[:at_id].present?
      if params[:at_id] == 'unread' && @user.present?
        reply = @unread = @post.first_unread_for(@user)
        @paginate_params['at_id'] = @unread.try(:id)
      else
        reply = Reply.find_by_id(params[:at_id].to_i)
      end

      if reply && reply.post_id == @post.id
        @replies = @replies.where('replies.reply_order >= ?', reply.reply_order)
        page = @cur_page = @cur_page.to_i
      else
        @errors.add(:base, "Could not locate specified reply, defaulting to first page.")
        page = @cur_page = 1
      end
    elsif @cur_page == 'last'
      page = @cur_page = @post.replies.paginate(per_page: @per, page: 1).total_pages
    elsif @cur_page == 'unread'
      if @user.present?
        @unread = @post.first_unread_for(@user)
        if @unread.nil?
          page = @cur_page = @post.replies.paginate(per_page: @per, page: 1).total_pages
        elsif @unread.class == Post
          page = @cur_page = 1
        else
          page = @cur_page = @unread.post_page(@per)
        end
      else
        @errors.add(:base, "You must be logged in to view unread posts.")
        page = @cur_page = 1
      end
    else
      page = @cur_page = @cur_page.to_i
    end
    page
  end

  def fetch_replies
    @replies
      .select("replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username, character_aliases.name as alias, users.deleted as user_deleted")
      .joins(:user)
      .left_outer_joins(:character)
      .left_outer_joins(:icon)
      .left_outer_joins(:character_alias)
      .with_edit_audit_counts
      .ordered
      .paginate(page: @cur_page, per_page: @per)
  end

  def get_next
    section_sequence
  end

  def get_prev
    section_sequence(true)
  end

  def canon_params
    canon_params = {}
    canon_params[:per_page] = @per unless @per == 25
    canon_params[:page] = @cur_page unless @cur_page == 1
    canon_params
  end

  private

  def section_sequence(prev=false)
    posts = Post.where(board_id: @post.board_id, section_id: @post.section_id).visible_to(@user).ordered_in_section
    posts = posts.reverse_order if prev
    posts.find_by("section_order #{prev ? '<' : '>'} ?", @post.section_order)
  end
end
