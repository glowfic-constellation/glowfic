# frozen_string_literal: true
class WritableController < ApplicationController
  protected

  def build_template_groups
    return unless logged_in?

    faked = Struct.new(:name, :id, :plucked_characters)
    pluck = "id, concat_ws(' | ', name, template_name, screenname)"
    templates = current_user.templates.order('LOWER(name)')
    templateless = faked.new('Templateless', nil, current_user.characters.where(:template_id => nil).order('LOWER(name) ASC').pluck(pluck))
    @templates = templates + [templateless]

    if @post
      uniq_chars_ids = @post.replies.where(user_id: current_user.id).where('character_id is not null').group(:character_id).pluck(:character_id)
      uniq_chars_ids << @post.character_id if @post.user_id == current_user.id && @post.character_id.present?
      uniq_chars = Character.where(id: uniq_chars_ids).order('LOWER(name)').pluck(pluck)
      threadchars = faked.new('Thread characters', nil, uniq_chars)
      @templates.insert(0, threadchars)
    end
    @templates.reject! {|template| template.plucked_characters.empty? }

    gon.current_user = current_user.gon_attributes
  end

  def show_post(cur_page=nil)
    per = per_page
    cur_page ||= page
    @replies = @post.replies
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
        @replies = @replies.where('replies.id >= ?', reply.id)
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

    @replies = @replies
      .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username, character_aliases.name as alias')
      .joins(:user)
      .joins("LEFT OUTER JOIN characters ON characters.id = replies.character_id")
      .joins("LEFT OUTER JOIN icons ON icons.id = replies.icon_id")
      .joins("LEFT OUTER JOIN character_aliases ON character_aliases.id = replies.character_alias_id")
      .order('id asc')
      .paginate(page: cur_page, per_page: per)
    redirect_to post_path(@post, page: @replies.total_pages, per_page: per) and return if cur_page > @replies.total_pages
    use_javascript('paginator')

    unless @post.board.open_to_anyone?
      @next_post = Post.where(board_id: @post.board_id).where(section_id: @post.section_id).where(section_order: @post.section_order + 1).first
      @prev_post = Post.where(board_id: @post.board_id).where(section_id: @post.section_id).where(section_order: @post.section_order - 1).first
    end

    # show <link rel="canonical"> – for SEO stuff
    canon_params = {}
    canon_params[:per_page] = per unless per == 25
    canon_params[:page] = cur_page unless cur_page == 1
    @meta_canonical = post_url(@post, canon_params)

    use_javascript('posts/show')
    if logged_in?
      use_javascript('posts/editor')

      if @post.taggable_by?(current_user)
        build_template_groups
        @reply = @post.build_new_reply_for(current_user)
      end

      @post.mark_read(current_user, @post.read_time_for(@replies))
    end

    @warnings = @post.content_warnings if display_warnings?

    render 'posts/show'
  end

  def display_warnings?
    return false if session[:ignore_warnings]

    if params[:ignore_warnings].present?
      session[:ignore_warnings] = true unless current_user
      return false
    end

    return true unless current_user
    @post.show_warnings_for?(current_user)
  end
end
