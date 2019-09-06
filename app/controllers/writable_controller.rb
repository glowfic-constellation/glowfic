# frozen_string_literal: true
class WritableController < ApplicationController
  protected

  def build_template_groups(user=nil)
    return unless logged_in?
    user ||= current_user

    faked = Struct.new(:name, :id, :plucked_characters)
    pluck = Arel.sql("id, concat_ws(' | ', name, template_name, screenname)")
    templates = user.templates.ordered
    templateless = faked.new('Templateless', nil, user.characters.where(template_id: nil).ordered.pluck(pluck))
    @templates = templates + [templateless]

    if @post
      uniq_chars_ids = @post.replies.where(user_id: user.id).where('character_id is not null').group(:character_id).pluck(:character_id)
      uniq_chars_ids << @post.character_id if @post.user_id == user.id && @post.character_id.present?
      uniq_chars = Character.where(id: uniq_chars_ids).ordered.pluck(pluck)
      threadchars = faked.new('Thread characters', nil, uniq_chars)
      @templates.insert(0, threadchars)
    end
    @templates.reject! {|template| template.plucked_characters.empty? }

    gon.editor_user = user.gon_attributes
  end

  def show_post(cur_page=nil)
    cur_page ||= page
    per = per_page
    displayer = Post::Displayer.new(@post, per: per, cur_page: cur_page, user: current_user)
    self.page = displayer.find_page(params)
    @unread = displayer.unread
    @paginate_params = displayer.paginate_params
    flash.now[:error] = displayer.errors.full_messages.first if displayer.errors.present?

    @replies = displayer.fetch_replies

    if displayer.cur_page > @replies.total_pages
      redirect_to post_path(@post, page: @replies.total_pages, per_page: per)
      return
    end

    use_javascript('paginator')

    if @post.board.ordered?
      @next_post = displayer.get_next
      @prev_post = displayer.get_prev
    end

    # show <link rel="canonical"> – for SEO stuff
    @meta_canonical = post_url(@post, displayer.canon_params)

    # show <meta property="og:..." content="..."> – for embed data
    @meta_og = og_data_for_post(@post, self.page, @replies.total_pages, per)
    @meta_og[:url] = @meta_canonical

    use_javascript('posts/show')
    if logged_in?
      use_javascript('posts/editor')
      setup_layout_gon

      if @post.taggable_by?(current_user)
        build_template_groups
        session_params = ActionController::Parameters.new(reply: session.fetch(:attempted_reply, {}))
        reply_hash = reply_params(session_params)
        session.delete(:attempted_reply)
        @reply = @post.build_new_reply_for(current_user, reply_hash)
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

  def editor_setup
    use_javascript('posts/editor')
    build_template_groups(@reply.try(:user) || @post.try(:user))
    setup_layout_gon
  end

  def setup_layout_gon
    return unless logged_in?
    gon.base_url = ENV['DOMAIN_NAME'] ? "https://#{ENV['DOMAIN_NAME']}/" : '/'
    gon.editor_class = 'layout_' + current_user.layout if current_user.layout
    gon.tinymce_css_path = helpers.stylesheet_path('tinymce')
    gon.no_icon_path = view_context.image_path('icons/no-icon.png')
  end

  def og_data_for_post(post, page, total_pages, per_page)
    post_location = post.board.name
    post_location += ' » ' + post.section.name if post.section.present?

    post_description = generate_short(post.description)
    post_description += ' ('
    post_description += helpers.author_links(post, linked: false)
    post_description += " – page #{page} of #{total_pages}"
    post_description += ", #{per_page}/page" unless per_page == 25
    post_description += ')'
    post_description.strip!

    @meta_og = {
      title: post.subject + ' · ' + post_location,
      description: post_description,
    }
  end

  def reply_params(param_hash=nil)
    (param_hash || params).fetch(:reply, {}).permit(
      :post_id,
      :content,
      :character_id,
      :icon_id,
      :audit_comment,
      :character_alias_id,
    )
  end
end
