# frozen_string_literal: true
class CharactersController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :facecasts, :search]
  before_filter :find_character, :only => [:show, :edit, :update, :duplicate, :destroy, :icon, :replace, :do_replace]
  before_filter :find_group, :only => :index
  before_filter :require_own_character, :only => [:edit, :update, :duplicate, :destroy, :icon, :replace, :do_replace]
  before_filter :build_editor, :only => [:new, :edit]

  def index
    (return if login_required) unless params[:user_id].present?

    @user = User.find_by_id(params[:user_id]) || current_user
    unless @user
      flash[:error] = "User could not be found."
      redirect_to users_path and return
    end

    @page_title = if @user.id == current_user.try(:id)
      "Your Characters"
    else
      @user.username + "'s Characters"
    end
  end

  def new
    @page_title = 'New Character'
    @character = Character.new(template_id: params[:template_id])
  end

  def create
    reorder_galleries and return if params[:commit] == "reorder"

    @character = Character.new(character_params)
    @character.user = current_user
    @character.build_new_tags_with(current_user)

    if @character.valid?
      save_character_with_extras
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      @page_title = 'New Character'
      flash.now[:error] = "Your character could not be saved."
      build_editor
      render :action => :new
    end
  end

  def show
    @page_title = @character.name
    @posts = posts_from_relation(@character.recent_posts)
    use_javascript('characters/show') if @character.user_id == current_user.try(:id)
  end

  def edit
    @page_title = 'Edit Character: ' + @character.name
  end

  def update
    @character.assign_attributes(character_params)
    @character.build_new_tags_with(current_user)

    if @character.valid?
      save_character_with_extras
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      flash.now[:error] = "Your character could not be saved."
      @page_title = 'Edit Character: ' + @character.name
      build_editor
      render :action => :edit
    end
  end

  def duplicate
    Character.transaction do
      @dup = @character.dup
      @dup.gallery_groups = @character.gallery_groups
      @dup.ungrouped_gallery_ids = @character.ungrouped_gallery_ids
      @character.aliases.find_each do |calias|
        dupalias = calias.dup
        @dup.aliases << dupalias
        dupalias.save
      end
      @dup.save
    end

    flash[:success] = "Character duplicated successfully. You are now editing the new character."
    redirect_to edit_character_path(@dup)
  end

  def destroy
    @character.destroy
    flash[:success] = "Character deleted successfully."
    redirect_to characters_path
  end

  def facecasts
    @page_title = 'Facecasts'
    chars = Character.where('pb is not null').includes(:user, :template)
    @pbs = {}

    if params[:sort] == "name"
      chars.each do |character|
        key = character.template || character
        @pbs[key] ||= []
        @pbs[key] << character.pb
      end
    elsif params[:sort] == "writer"
      chars.each do |character|
        @pbs[character.user] ||= {}
        @pbs[character.user][character.pb] ||= []
        @pbs[character.user][character.pb] << (character.template || character)
      end
    else
      chars.each do |character|
        @pbs[character.pb] ||= []
        @pbs[character.pb] << (character.template || character)
      end
    end
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
        [alt.id, {url: alt.default_icon.url, keyword: alt.default_icon.keyword, aliases: alt.aliases.as_json}]
      else
        [alt.id, {url: '/images/no-icon.png', keyword: 'No Icon', aliases: alt.aliases.as_json}]
      end
    end
    gon.gallery = Hash[icons]
    gon.gallery[''] = {url: '/images/no-icon.png', keyword: 'No Character'}

    @alt_dropdown = @alts.map do |alt|
      name = alt.name
      name += ' | ' + alt.screenname if alt.screenname
      name += ' | ' + alt.template_name if alt.template_name
      name += ' | ' + alt.setting if alt.setting
      [name, alt.id]
    end
    @alt = @alts.first

    all_posts = Post.where(character_id: @character.id) + Post.where(id: Reply.where(character_id: @character.id).pluck('distinct post_id'))
    @posts = all_posts.uniq
  end

  def do_replace
    unless params[:icon_dropdown].blank? || (new_char = Character.find_by_id(params[:icon_dropdown]))
      flash[:error] = "Character could not be found."
      redirect_to replace_character_path(@character) and return
    end

    if new_char && new_char.user_id != current_user.id
      flash[:error] = "That is not your character."
      redirect_to replace_character_path(@character) and return
    end

    orig_alias = nil
    if params[:orig_alias].present? && params[:orig_alias] != 'all'
      orig_alias = CharacterAlias.find_by_id(params[:orig_alias])
      unless orig_alias && orig_alias.character_id == @character.id
        flash[:error] = "Invalid old alias."
        redirect_to replace_character_path(@character) and return
      end
    end

    new_alias_id = nil
    if params[:alias_dropdown].present?
      new_alias = CharacterAlias.find_by_id(params[:alias_dropdown])
      unless new_alias && new_alias.character_id == new_char.try(:id)
        flash[:error] = "Invalid new alias."
        redirect_to replace_character_path(@character) and return
      end
      new_alias_id = new_alias.id
    end

    Post.transaction do
      replies = Reply.where(character_id: @character.id)
      posts = Post.where(character_id: @character.id)

      if params[:post_ids].present?
        replies = replies.where(post_id: params[:post_ids])
        posts = posts.where(id: params[:post_ids])
      end

      if @character.aliases.exists? && params[:orig_alias] != 'all'
        replies = replies.where(character_alias_id: orig_alias.try(:id))
        posts = posts.where(character_alias_id: orig_alias.try(:id))
      end

      posts.update_all(character_id: new_char.try(:id), character_alias_id: new_alias_id)
      replies.update_all(character_id: new_char.try(:id), character_alias_id: new_alias_id)
    end

    flash[:success] = "All uses of this character have been replaced."
    redirect_to character_path(@character)
  end

  def search
    @page_title = 'Search Characters'
    use_javascript('posts/search')
    @users = []
    @templates = []
    return unless params[:commit].present?

    @search_results = Character.unscoped

    if params[:author_id].present?
      # TODO display error if the user doesn't exist
      @users = User.where(id: params[:author_id])
      @search_results = @search_results.where(user_id: params[:author_id])
    end

    if params[:template_id].present?
      # TODO display error if the template doesn't exist
      # TODO display error if template is not user's
      @templates = Template.where(id: params[:template_id])
      @search_results = @search_results.where(template_id: params[:template_id])
    end

    if params[:name].present?
      where_calc = []
      where_calc << "name LIKE ?" if params[:search_name].present?
      where_calc << "screenname LIKE ?" if params[:search_screenname].present?
      where_calc << "template_name LIKE ?" if params[:search_nickname].present?

      @search_results = @search_results.where(where_calc.join(' OR '), *(['%' + params[:name].to_s + '%'] * where_calc.length))
    end

    @search_results = @search_results.order('name asc').paginate(page: page, per_page: 25)
  end

  private

  def find_character
    unless (@character = Character.find_by_id(params[:id]))
      flash[:error] = "Character could not be found."
      redirect_to characters_path and return
    end
  end

  def find_group
    return unless params[:group_id].present?
    @group = CharacterGroup.find_by_id(params[:group_id])
  end

  def require_own_character
    unless @character.user_id == current_user.id
      flash[:error] = "You do not have permission to edit that character."
      redirect_to characters_path and return
    end
  end

  def build_editor
    faked = Struct.new(:name, :id)
    new_template = faked.new('— Create New Template —', 0)
    @templates = current_user.templates.order('name asc') + [new_template]
    new_group = faked.new('— Create New Group —', 0)
    @groups = current_user.character_groups.order('name asc') + [new_group]
    use_javascript('characters/editor')
    build_tags
    gon.character_id = @character.try(:id) || ''
    gon.user_id = current_user.id
    @aliases = @character.aliases.order('name asc') if @character
    gon.gallery_groups = @gallery_groups.map {|group| group.as_json(include: [:gallery_ids], user_id: current_user.id) }
  end

  def build_tags
    @gallery_groups = @character.try(:gallery_groups) || []
  end

  def save_character_with_extras
    Character.transaction do
      if (template = @character.instance_variable_get('@template'))
        template.save
        @character.template = template
      end
      if (group = @character.instance_variable_get('@group'))
        group.save
        @character.character_group = group
      end
      @character.save
    end
  end

  def reorder_galleries
    CharactersGallery.transaction do
      params[:changes].each do |id, order|
        cg = CharactersGallery.find_by_id(id)
        next unless cg
        cg.section_order = order
        cg.save
      end
    end
    render json: {}
  end

  def character_params
    params.fetch(:character, {}).permit(:default_icon_id, :name, :template_name, :screenname, :setting, :template_id, :new_template_name, :pb, :description, ungrouped_gallery_ids: [], gallery_group_ids: [])
  end
end
