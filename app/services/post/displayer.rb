class Post::Displayer < Generic::Service
  attr_reader :unread, :paginate_params

  def initialize(post, user:, per:, cur_page:)
    @post = post
    @replies = @post.replies
    @user = user
    @per = per
    @cur_page = cur_page
  end

  def find_page
    @paginate_params = {controller: 'posts', action: 'show', id: @post.id}
    if params[:at_id].present?
      reply = if params[:at_id] == 'unread' && logged_in?
        @unread = @post.first_unread_for(current_user)
        @paginate_params['at_id'] = @unread.try(:id)
        @unread
      else
        Reply.find_by_id(params[:at_id].to_i)
      end

      if reply && reply.post_id == @post.id
        @replies = @replies.where('replies.reply_order >= ?', reply.reply_order)
        self.page = cur_page = cur_page.to_i
      else
        flash[:error] = "Could not locate specified reply, defaulting to first page."
        self.page = cur_page = 1
      end
    elsif cur_page == 'last'
      self.page = cur_page = @post.replies.paginate(per_page: per, page: 1).total_pages
    elsif cur_page == 'unread'
      if logged_in?
        @unread = @post.first_unread_for(current_user) if logged_in?
        if @unread.nil?
          self.page = cur_page = @post.replies.paginate(per_page: per, page: 1).total_pages
        elsif @unread.class == Post
          self.page = cur_page = 1
        else
          self.page = cur_page = @unread.post_page(per)
        end
      else
        flash.now[:error] = "You must be logged in to view unread posts."
        self.page = cur_page = 1
      end
    else
      self.page = cur_page = cur_page.to_i
    end
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
      .paginate(page: cur_page, per_page: per)
  end

  def get_next
    posts = Post.where(board_id: @post.board_id, section_id: @post.section_id).visible_to(current_user).ordered_in_section
    @next_post = posts.find_by('section_order > ?', @post.section_order)
  end

  def get_prev
    posts = Post.where(board_id: @post.board_id, section_id: @post.section_id).visible_to(current_user).ordered_in_section
    @prev_post = posts.reverse_order.find_by('section_order < ?', @post.section_order)
  end

  def get_url
    canon_params = {}
    canon_params[:per_page] = per unless per == 25
    canon_params[:page] = cur_page unless cur_page == 1
    @meta_canonical = post_url(@post, canon_params)
  end

  def fetch_attempted_reply(session)
    session_params = ActionController::Parameters.new(reply: session.fetch(:attempted_reply, {}))
    reply_hash = reply_params(session_params)
    session.delete(:attempted_reply)
    @reply = @post.build_new_reply_for(current_user, reply_hash)
  end
end
