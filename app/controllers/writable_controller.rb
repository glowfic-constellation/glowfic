class WritableController < ApplicationController
  protected

  def build_template_groups
    return unless logged_in?

    templates = current_user.templates.sort_by(&:name)
    faked = Struct.new(:name, :id, :ordered_characters)
    templateless = faked.new('Templateless', nil, current_user.characters.where(:template_id => nil).to_a)
    @templates = templates + [templateless]

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

    per = per_page > 0 ? per_page : replies.count
    cur_page ||= page
    @replies = replies.includes(:user, :character, :post, :icon).order('id asc').paginate(page: cur_page, per_page: per)
    redirect_to post_path(@post, page: @replies.total_pages, per_page: per) and return if page > @replies.total_pages
    use_javascript('paginator')

    @next_post = Post.where(board_id: @post.board_id).where("id > #{@post.id}").order('id asc').limit(1).first
    @prev_post = Post.where(board_id: @post.board_id).where("id < #{@post.id}").order('id desc').limit(1).first

    if logged_in?
      use_javascript('posts')
      
      active_char = @post.last_character_for(current_user)
      @reply = Reply.new(post: @post, 
        character: active_char,
        user: current_user, 
        icon: active_char.try(:icon))
      @character = active_char
      @image = @character ? @character.icon : current_user.avatar

      at_time = if @replies.empty?
        @post.updated_at
      else
        @replies.map(&:updated_at).max
      end
      @post.mark_read(current_user, at_time) unless @post.board.ignored_by?(current_user)
    end

    render 'posts/show'
  end
end
