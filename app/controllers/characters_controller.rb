# frozen_string_literal: true
class CharactersController < ApplicationController
  before_filter :login_required, except: [:index, :show, :facecasts, :search]
  before_filter :find_character, only: [:show, :edit, :update, :duplicate, :destroy, :icon, :replace, :do_replace]
  before_filter :find_group, only: :index
  before_filter :require_own_character, only: [:edit, :update, :duplicate, :destroy, :icon, :replace, :do_replace]
  before_filter :build_editor, only: [:new, :edit]

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
    @character.build_template(user: current_user) unless @character.template
  end

  def create
    @character = Character.new(character_params)
    @character.user = current_user
    @character.build_new_tags_with(current_user)
    build_template

    if @character.save
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character) and return
    end

    @page_title = "New Character"
    flash.now[:error] = {}
    flash.now[:error][:message] = "Your character could not be saved."
    flash.now[:error][:array] = @character.errors.full_messages
    build_editor
    render action: :new
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
    build_template

    if @character.save
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character) and return
    end

    @page_title = "Edit Character: " + @character.name
    flash.now[:error] = {}
    flash.now[:error][:message] = "Your character could not be saved."
    flash.now[:error][:array] = @character.errors.full_messages
    build_editor
    render :action => :edit
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
    chars = Character.where('pb is not null')
      .joins(:user)
      .joins('LEFT OUTER JOIN templates ON characters.template_id = templates.id')
      .pluck('characters.id, characters.name, characters.pb, users.id, users.username, templates.id, templates.name')
    @pbs = []

    chars.each do |dataset|
      id, name, pb, user_id, username, template_id, template_name = dataset
      if template_id.present?
        item_id, item_name, type = template_id, template_name, Template
      else
        item_id, item_name, type = id, name, Character
      end
      @pbs << {item_id: item_id, item_name: item_name, type: type, pb: pb, user_id: user_id, username: username}
    end
    @pbs.uniq!

    if params[:sort] == "name"
      @pbs.sort_by! {|x| x[:item].name.downcase}
    elsif params[:sort] == "writer"
      @pbs.sort_by! {|x| x[:user].username.downcase}
    else
      @pbs.sort_by! {|x| x[:pb].downcase}
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
      @users = User.where(id: params[:author_id])
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
    else
      @templates = Template.where(user_id: params[:author_id]).order('name asc').limit(25) if params[:author_id].present?
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

  # logic replicated from page_view
  def character_split
    return @character_split if @character_split
    if logged_in?
      @character_split = params[:character_split] || current_user.default_character_split
    else
      @character_split = session[:character_split] = params[:character_split] || session[:character_split] || 'template'
    end
  end
  helper_method :character_split

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
    unless @character.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit that character."
      redirect_to characters_path and return
    end
  end

  def build_editor
    faked = Struct.new(:name, :id)
    @templates = current_user.templates.order('name asc')
    new_group = faked.new('— Create New Group —', 0)
    @groups = current_user.character_groups.order('name asc') + [new_group]
    use_javascript('characters/editor')
    build_tags
    gon.character_id = @character.try(:id) || ''
    @character.build_template(user: current_user) if @character && @character.template.nil?
    gon.user_id = current_user.id
    @aliases = @character.aliases.order('name asc') if @character
    gon.gallery_groups = @gallery_groups.map {|group| group.as_json(include: [:gallery_ids], user_id: current_user.id) }
  end

  def build_tags
    @gallery_groups = @character.gallery_groups.order('character_tags.id asc') if @character.try(:persisted?)
    @gallery_groups ||= @character.try(:gallery_groups) || []
  end

  def build_template
    return unless params[:new_template].present?
    @character.build_template unless @character.template
    @character.template.user = current_user
  end

  def character_params
    params.fetch(:character, {}).permit(:default_icon_id, :name, :template_name, :screenname, :setting, :template_id, :pb, :description, ungrouped_gallery_ids: [], gallery_group_ids: [], template_attributes: [:name, :id])
  end
end
