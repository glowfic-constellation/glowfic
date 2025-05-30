# frozen_string_literal: true
class WritableController < ApplicationController
  protected

  def build_template_groups(user=nil)
    return unless logged_in?
    user ||= current_user
    user = current_user unless user.id == current_user.id || current_user.has_permission?(:edit_posts)

    faked = Struct.new(:name, :id, :plucked_characters)
    faked_npcs = Struct.new(:name, :id, :plucked_npcs)
    templates = user.templates.ordered
    templateless = faked.new(
      'Templateless', nil,
      user.characters.non_npcs.where(template_id: nil, retired: false).ordered.pluck(Template::CHAR_PLUCK),
    )
    @templates = templates + [templateless]
    all_npcs = faked_npcs.new('All NPCs', nil, user.characters.npcs.not_retired.ordered.pluck(Template::NPC_PLUCK))
    @npcs = [all_npcs]

    if @post
      uniq_chars_ids = @post.replies.where(user_id: user.id).where.not(character_id: nil).group(:character_id).pluck(:character_id)
      uniq_chars_ids << @post.character_id if @post.user_id == user.id && @post.character_id.present?
      uniq_chars = Character.non_npcs.where(id: uniq_chars_ids).ordered.pluck(Template::CHAR_PLUCK)
      threadchars = faked.new('Post characters', nil, uniq_chars)
      @templates.insert(0, threadchars)

      uniq_npcs = Character.npcs.where(id: uniq_chars_ids).ordered.pluck(Template::NPC_PLUCK)
      threadnpcs = faked_npcs.new('Post NPCs', nil, uniq_npcs)
      @npcs.insert(0, threadnpcs)
    end
    @templates.reject! { |template| template.plucked_characters.empty? }
    @npcs.reject! { |group| group.plucked_npcs.empty? }

    gon.editor_user = user.gon_attributes
  end

  def show_post(cur_page=nil)
    per = per_page
    cur_page ||= page(allow_special: true)
    @replies = @post.replies
    @paginate_params = { controller: 'posts', action: 'show', id: @post.id }

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

    select = <<~SQL.squish
      replies.*, characters.name, characters.screenname,
      icons.keyword, icons.url,
      users.username, users.deleted as user_deleted,
      character_aliases.name as alias
    SQL

    reply_count = @replies.count

    @replies = @replies
      .select(select)
      .joins(:user)
      .left_outer_joins(:character)
      .left_outer_joins(:icon)
      .left_outer_joins(:character_alias)
      .ordered
      .paginate(page: cur_page, per_page: per, total_entries: reply_count)
    redirect_to post_path(@post, page: @replies.total_pages, per_page: per) and return if cur_page > @replies.total_pages
    use_javascript('paginator')

    @audits = @post.associated_audits.where(auditable_id: @replies.map(&:id)).group(:auditable_id).count
    @audits[:post] = @post.audits.count

    calculate_reply_bookmarks(@replies)

    @next_post = @post.next_post(current_user)
    @prev_post = @post.prev_post(current_user)

    # show <link rel="canonical"> – for SEO stuff
    canon_params = {}
    canon_params[:per_page] = per unless per == 25
    canon_params[:page] = cur_page unless cur_page == 1
    @meta_canonical = post_url(@post, canon_params)

    # show <meta property="og:..." content="..."> – for embed data
    @meta_og = og_data_for_post(@post, page: self.page, total_pages: @replies.total_pages, per_page: per)
    @meta_og[:url] = @meta_canonical

    use_javascript('posts/show')
    if logged_in?
      use_javascript('posts/editor')
      setup_layout_gon

      if @post.taggable_by?(current_user)
        build_template_groups

        session_params = ActionController::Parameters.new(reply: session.fetch(:attempted_reply, {}))
        reply_hash = permitted_params(session_params)
        session.delete(:attempted_reply)

        @reply = @post.build_new_reply_for(current_user, reply_hash)
        @reply.editor_mode ||= params[:editor_mode] || current_user.default_editor
        @draft = ReplyDraft.draft_for(@post.id, current_user.id)
      end

      @post.mark_read(current_user, at_time: @post.read_time_for(@replies))
    end

    if display_warnings?
      @post_warnings = @post.content_warnings
      @author_warnings = @post.tagging_authors.includes(:user_tags).each_with_object({}) do |author, hash|
        hash[author] = author.user_tags unless author.user_tags.empty?
      end
    end

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

  def og_data_for_post(post, page: 1, total_pages:, per_page: 25)
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

  def make_draft(show_message=true)
    if (draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id))
      draft.assign_attributes(permitted_params)
    else
      draft = ReplyDraft.new(permitted_params)
      draft.user = current_user
    end
    process_npc(draft, permitted_character_params)
    new_npc = !draft.character.nil? && !draft.character.persisted?

    begin
      draft.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(draft, action: 'saved', class_name: 'Draft', err: e)
    else
      if show_message
        msg = "Draft saved."
        msg += " Your new NPC character has also been persisted!" if new_npc
        flash[:success] = msg
      end
    end
    draft
  end

  def process_npc(writable, permitted_character_params)
    return unless writable.character.nil?
    return unless permitted_character_params[:npc] == 'true'

    # we take the NPC's first post's subject as its nickname, for disambiguation in dropdowns etc
    # additionally, we grab the post's settings and attach those to the character
    post = if writable.is_a? Post
      writable
    else
      writable.post
    end

    writable.build_character(
      permitted_character_params.merge(
        default_icon_id: writable.icon_id,
        user_id: writable.user_id,
        nickname: post.subject,
        settings: post.settings,
      ),
    )
  end

  def permitted_params(param_hash=nil, extra_params=[])
    (param_hash || params).fetch(:reply, {}).permit(
      :post_id,
      :content,
      :character_id,
      :icon_id,
      :audit_comment,
      :character_alias_id,
      :editor_mode,
      *extra_params,
    )
  end

  def permitted_character_params(param_hash=nil)
    (param_hash || params).fetch(:character, {}).permit(
      :name,
      :npc,
    )
  end
end
