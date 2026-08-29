# frozen_string_literal: true
class CharactersController < ApplicationController
  include CharacterFilter

  before_action :login_required, except: [:index, :show, :facecasts, :search]
  before_action :find_model, only: [:show, :edit, :update, :duplicate, :destroy, :replace, :do_replace]
  before_action :find_group, only: :index
  before_action :require_create_permission, only: [:new, :create]
  before_action :require_edit_permission, only: [:edit, :update, :duplicate, :replace, :do_replace]
  before_action :editor_setup, only: [:new, :edit]

  def index
    unless params[:user_id].present?
      return if login_required
      return if readonly_forbidden
    end

    @user = if params[:user_id].present?
      User.active.full.find_by(id: params[:user_id])
    else
      current_user
    end

    unless @user
      flash[:error] = "User could not be found."
      redirect_to users_path and return
    end

    response.headers['X-Robots-Tag'] = 'noindex' if params[:view]
    @page_title = if @user.id == current_user.try(:id)
      "Your Characters"
    else
      @user.username + "'s Characters"
    end
  end

  def new
    @page_title = 'New Character'
    @character = Character.new(template_id: params[:template_id], user: current_user)
    @character.build_template(user: current_user) unless @character.template
  end

  def create
    @character = Character.new(user: current_user)
    creater = Character::Saver.new(@character, user: current_user, params: params)

    begin
      creater.create!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@character, action: 'created', now: true, err: e)

      @page_title = "New Character"
      editor_setup
      render :new
    else
      flash[:success] = "Character created."
      redirect_to @character
    end
  end

  def show
    @page_title = @character.name
    if params[:view] == 'posts'
      posts = @character.recent_posts
      posts = posts.not_ignored_by(current_user) if current_user&.hide_from_all
      @posts = posts_from_relation(posts)
    end
    @meta_og = og_data
    use_javascript('characters/show') if @character.user_id == current_user.try(:id)
    response.headers['X-Robots-Tag'] = 'noindex' if params[:view]
  end

  def edit
    @page_title = 'Edit Character: ' + @character.name
  end

  def update
    if current_user.id != @character.user_id && params.dig(:character, :audit_comment).blank?
      flash.now[:error] = "You must provide a reason for your moderator edit."
      editor_setup
      render :edit and return
    end

    updater = Character::Saver.new(@character, user: current_user, params: params)

    begin
      updater.update!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@character, action: 'updated', now: true, err: e)

      @page_title = "Edit Character: " + @character.name
      editor_setup
      render :edit
    else
      flash[:success] = "Character updated."
      redirect_to @character
    end
  end

  def duplicate
    dupe = @character.dup

    begin
      Character.transaction do
        dupe.gallery_groups = @character.gallery_groups
        dupe.settings = @character.settings
        dupe.ungrouped_gallery_ids = @character.ungrouped_gallery_ids
        @character.aliases.find_each do |calias|
          dupalias = calias.dup
          dupe.aliases << dupalias
          dupalias.save!
        end
        dupe.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      render_errors(dupe, action: 'duplicated', err: e)
      redirect_to @character
    else
      flash[:success] = "Character duplicated. You are now editing the new character."
      redirect_to edit_character_path(dupe)
    end
  end

  def destroy
    unless @character.deletable_by?(current_user)
      flash[:error] = "You do not have permission to modify this character."
      redirect_to user_characters_path(current_user) and return
    end

    begin
      @character.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@character, action: 'deleted', err: e)
      redirect_to @character
    else
      flash[:success] = "Character deleted."
      redirect_to user_characters_path(current_user)
    end
  end

  def facecasts
    @page_title = 'Facecasts'
    chars = Character.where(users: { deleted: false }).where.not(pb: nil)
      .joins(:user)
      .left_outer_joins(:template)
      .pluck('characters.id, characters.name, characters.pb, users.id, users.username, templates.id, templates.name')

    @pbs = chars.map { |data| Character.facecast_for(data) }.uniq

    case params[:sort]
      when "name"
        keys = [:name, :pb, :username]
      when "writer"
        keys = [:username, :pb, :name]
      else
        keys = [:pb, :username, :name]
    end

    @pbs.sort_by! { |x| x.to_h.values_at(*keys).map(&:downcase) }
  end

  def replace
    @page_title = 'Replace Character: ' + @character.name
    if @character.template
      @alts = @character.template.characters
    else
      @alts = @character.user.characters.where(template_id: nil)
    end
    @alts -= [@character] unless @alts.size <= 1 || @character.aliases.exists?
    use_javascript('icons')

    icons = @alts.map do |alt|
      if alt.default_icon.present?
        [alt.id, { url: alt.default_icon.url, keyword: alt.default_icon.keyword, aliases: alt.aliases.as_json }]
      else
        [alt.id, { url: view_context.image_path('icons/no-icon.png'), keyword: 'No Icon', aliases: alt.aliases.as_json }]
      end
    end
    gon.gallery = icons.to_h
    gon.gallery[''] = { url: view_context.image_path('icons/no-icon.png'), keyword: 'No Character' }

    @alt_dropdown = @alts.map { |alt| [alt.selector_name(include_settings: true), alt.id] }
    @alt = @alts.first

    reply_post_ids = Reply.where(character_id: @character.id).select(:post_id).distinct.pluck(:post_id)
    all_posts = Post.where(character_id: @character.id) + Post.where(id: reply_post_ids)
    @posts = all_posts.uniq
  end

  def do_replace
    unless params[:icon_dropdown].blank? || (new_char = Character.find_by(id: params[:icon_dropdown]))
      flash[:error] = "Character could not be found."
      redirect_to replace_character_path(@character) and return
    end

    if new_char && new_char.user_id != current_user.id
      flash[:error] = "You do not have permission to modify this character."
      redirect_to replace_character_path(@character) and return
    end

    orig_alias = nil
    if params[:orig_alias].present? && params[:orig_alias] != 'all'
      orig_alias = CharacterAlias.find_by(id: params[:orig_alias])
      unless orig_alias && orig_alias.character_id == @character.id
        flash[:error] = "Invalid old alias."
        redirect_to replace_character_path(@character) and return
      end
    end

    new_alias_id = nil
    if params[:alias_dropdown].present?
      new_alias = CharacterAlias.find_by(id: params[:alias_dropdown])
      unless new_alias && new_alias.character_id == new_char.try(:id)
        flash[:error] = "Invalid new alias."
        redirect_to replace_character_path(@character) and return
      end
      new_alias_id = new_alias.id
    end

    success_msg = ''
    wheres = { character_id: @character.id }
    updates = { character_id: new_char.try(:id), character_alias_id: new_alias_id }

    if params[:post_ids].present?
      wheres[:post_id] = params[:post_ids]
      success_msg = " in the specified " + 'post'.pluralize(params[:post_ids].size)
    end

    wheres[:character_alias_id] = orig_alias.try(:id) if @character.aliases.exists? && params[:orig_alias] != 'all'

    UpdateModelJob.perform_later(Reply.to_s, wheres, updates, current_user.id)
    wheres[:id] = wheres.delete(:post_id) if params[:post_ids].present?
    UpdateModelJob.perform_later(Post.to_s, wheres, updates, current_user.id)

    flash[:success] = "All uses of this character#{success_msg} will be replaced."
    redirect_to @character
  end

  def search
    @page_title = 'Search Characters'
    use_javascript('search')
    @users = []
    @templates = []
    return unless params[:commit].present?

    response.headers['X-Robots-Tag'] = 'noindex'
    @search_results = Character.unscoped

    if params[:author_id].present?
      @users = User.active.where(id: params[:author_id])
      if @users.present?
        @search_results = @search_results.where(user_id: params[:author_id])
      else
        flash.now[:error] = "The specified author could not be found."
      end
    end

    if params[:template_id].present?
      @templates = Template.where(id: params[:template_id])
      template = @templates.first
      if template.present?
        if @users.present? && template.user_id != @users.first.id
          flash.now[:error] = "The specified author and template do not match; template filter will be ignored."
          @templates = []
        else
          @search_results = @search_results.where(template_id: params[:template_id])
        end
      else
        flash.now[:error] = "The specified template could not be found."
      end
    elsif params[:author_id].present?
      @templates = Template.where(user_id: params[:author_id]).ordered.limit(25)
    end

    if params[:name].present?
      where_calc = []
      where_calc << "name ILIKE ?" if params[:search_name].present?
      where_calc << "screenname ILIKE ?" if params[:search_screenname].present?
      where_calc << "nickname ILIKE ?" if params[:search_nickname].present?

      @search_results = @search_results.where(where_calc.join(' OR '), *(['%' + params[:name].to_s + '%'] * where_calc.length))
    end

    @search_results = @search_results.ordered.paginate(page: page)
  end

  private

  def find_model
    return if (@character = Character.find_by(id: params[:id]))
    flash[:error] = "Character could not be found."
    if logged_in?
      redirect_to user_characters_path(current_user)
    else
      redirect_to root_path
    end
  end

  def find_group
    return unless params[:group_id].present?
    @group = CharacterGroup.find_by(id: params[:group_id])
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create characters."
    redirect_to continuities_path and return
  end

  def require_edit_permission
    return if @character.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this character."
    redirect_to user_characters_path(current_user)
  end

  def editor_setup
    faked = Struct.new(:name, :id)
    user = @character.try(:user) || current_user
    @templates = user.templates.ordered
    new_group = faked.new('— Create New Group —', 0)
    @groups = user.character_groups.order(:name) + [new_group]
    use_javascript('characters/editor')
    gon.character_id = @character.try(:id) || ''
    @character.build_template(user: user) if @character.present? && @character.template.nil? && @character.user == current_user
    gon.user_id = user.id
    @aliases = @character.aliases.ordered if @character
    gon.mod_editing = (user != current_user)
    groups = @character.try(:gallery_groups) || []
    gon.gallery_groups = groups.map { |group| group.as_json(include: [:gallery_ids], user_id: user.id) }
  end

  def og_data
    # User >> Template >> Character | screenname
    # Nickname(s): a, b. Settings: c, d
    # Description
    # n posts.

    character_desc = [@character.name, @character.screenname].compact_blank.join(' | ')
    title = [character_desc]
    title.prepend(@character.template.name) if @character.template.present?
    title.prepend(@character.user.username) unless @character.user.deleted?

    linked = []
    nicknames = ([@character.nickname] + @character.aliases.pluck(:name)).uniq.compact

    nickname_prefix = if @character.npc?
      "Original post"
    else
      "Nickname"
    end
    linked << (nickname_prefix.pluralize(nicknames.count) + ": " + nicknames.join(', ')) if nicknames.present?
    settings = @character.settings.pluck(:name)
    linked << ("Setting".pluralize(settings.count) + ": " + settings.join(', ')) if settings.present?
    desc = [linked.join('. ')].compact_blank
    desc << generate_short(@character.description) if @character.description.present?
    reply_posts = Reply.where(character_id: @character.id).select(:post_id).distinct.pluck(:post_id)
    posts_count = Post.where(character_id: @character.id).or(Post.where(id: reply_posts)).privacy_public.uniq.count
    desc << "#{posts_count} #{'post'.pluralize(posts_count)}" if posts_count > 0
    data = {
      url: character_url(@character),
      title: title.join(' » '),
      description: desc.join("\n"),
    }
    if @character.default_icon.present?
      data[:image] = {
        src: @character.default_icon.url,
        width: '75',
        height: '75',
      }
    end
    data
  end
end
