class WritableController < ApplicationController
  protected

  def build_template_groups
    return unless logged_in?

    templates = current_user.templates.includes(:characters).sort_by(&:name)
    faked = Struct.new(:name, :id, :ordered_characters)
    templateless = faked.new('Templateless', nil, current_user.characters.where(:template_id => nil).to_a.sort_by(&:name))
    @templates = templates + [templateless]
    
    if @post
      uniq_chars_ids = @post.replies.where(user_id: current_user.id).select(:character_id).group(:character_id).map(&:character_id).uniq
      uniq_chars_ids << @post.character_id if @post.user_id == current_user.id
      uniq_chars = Character.where(id: uniq_chars_ids.compact).to_a
      threadchars = faked.new('Thread characters', nil, uniq_chars.sort_by(&:name))
      @templates.insert(0, threadchars)
    end

    gon.current_user = current_user.gon_attributes
    gon.character_path = character_user_path(current_user)
  end

  def show_post(cur_page=nil)
    @threaded = false
    replies = if @post.replies.where('thread_id is not null').count > 1
      @threaded = true
      if params[:thread_id].present?
        @replies = @post.replies.where(thread_id: params[:thread_id])
      else
        @post.replies.where('id = thread_id')
      end
    else
      @post.replies
    end

    @unread = @post.first_unread_for(current_user) if logged_in?
    if per_page > 0
      per = per_page
      cur_page ||= page
      if cur_page == 'last'
        self.page = cur_page = @post.replies.paginate(per_page: per, page: 1).total_pages
      elsif cur_page == 'unread'
        if logged_in?
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
    else
      per = replies.count
      self.page = cur_page = 1
    end

    @replies = replies.includes(:user, :character, :icon).order('id asc').paginate(page: cur_page, per_page: per)
    @paginate_params = {controller: 'posts', action: 'show', id: @post.id}
    redirect_to post_path(@post, page: @replies.total_pages, per_page: per) and return if cur_page > @replies.total_pages
    use_javascript('paginator')

    @next_post = Post.where(board_id: @post.board_id).where("id > #{@post.id}").order('id asc').limit(1).first
    @prev_post = Post.where(board_id: @post.board_id).where("id < #{@post.id}").order('id desc').limit(1).first

    if logged_in?
      use_javascript('posts')
      
      active_char = @post.last_character_for(current_user)
      @reply = ReplyDraft.draft_reply_for(@post, current_user) || Reply.new(
        post: @post,
        character: active_char,
        user: current_user, 
        icon: active_char.try(:icon))
      @character = @reply.character
      @image = @character ? @character.icon : current_user.avatar
      gon.original_content = @reply.content

      at_time = (@replies.map(&:updated_at) + [@post.edited_at]).max
      @post.mark_read(current_user, at_time) unless @post.board.ignored_by?(current_user)
    end

    render 'posts/show'
  end
end
