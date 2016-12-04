class CharactersController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :facecasts]
  before_filter :find_character, :only => [:show, :edit, :update, :destroy, :icon, :replace, :do_replace]
  before_filter :find_group, :only => :index
  before_filter :require_own_character, :only => [:edit, :update, :destroy, :icon, :replace, :do_replace]
  before_filter :build_editor, :only => [:new, :create, :edit, :update]

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
    @characters = @user.characters.order('name asc')
  end

  def new
    @page_title = 'New Character'
    @character = Character.new(template_id: params[:template_id])
  end

  def create
    reorder_galleries and return if params[:commit] == "reorder"

    @character = Character.new((params[:character] || {}).merge(user: current_user))

    if @character.valid?
      save_character_with_extras
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      @page_title = 'New Character'
      flash.now[:error] = "Your character could not be saved."
      render :action => :new
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: CharacterPresenter.new(@character)
      end
      format.html do
        @page_title = @character.name
        @posts = @character.recent_posts(25, page).includes(:board, :user, :last_user, :content_warnings)
        use_javascript('characters/show') if @character.user_id == current_user.try(:id)
        use_javascript('galleries/index') if @character.galleries.ordered.present?
      end
    end
  end

  def edit
    @page_title = 'Edit Character: ' + @character.name
  end

  def update
    @character.assign_attributes(params[:character])

    if @character.valid?
      save_character_with_extras
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      flash.now[:error] = "Your character could not be saved."
      @page_title = 'Edit Character: ' + @character.name
      render :action => :edit
    end
  end

  def destroy
    @character.destroy
    flash[:success] = "Character deleted successfully."
    redirect_to characters_path
  end

  def icon
    icon = Icon.find_by_id(params[:icon_id])
    @character.update_attributes(default_icon: icon) if icon && icon.user_id == current_user.id
    render :json => {}
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
    @alts -= [@character]
    use_javascript('icons')

    icons = @alts.map do |alt|
      if alt.icon.present?
        [alt.id, {url: alt.icon.url, keyword: alt.icon.keyword}]
      else
        [alt.id, {url: '/images/no-icon.png', keyword: 'No Icon'}]
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

    all_posts = Post.where(character_id: @character.id) + Reply.where(character_id: @character.id).select(:post_id).group(:post_id).map(&:post)
    @posts = all_posts.uniq
  end

  def do_replace
    unless params[:icon_dropdown].blank? || new_char = Character.find_by_id(params[:icon_dropdown])
      flash[:error] = "Character could not be found."
      redirect_to replace_character_path(@character)
    end

    if new_char && new_char.user_id != current_user.id
      flash[:error] = "That is not your character."
      redirect_to replace_character_path(@character)
    end

    Post.transaction do
      replies = Reply.where(character_id: @character.id)
      replies = replies.where(post_id: params[:post_ids]) if params[:post_ids].present?
      replies.update_all(character_id: new_char.try(:id))

      posts = Post.where(character_id: @character.id)
      posts = posts.where(id: params[:post_ids]) if params[:post_ids].present?
      posts.update_all(character_id: new_char.try(:id))
    end

    flash[:success] = "All uses of this character have been replaced."
    redirect_to character_path(@character)
  end

  private

  def find_character
    unless @character = Character.find_by_id(params[:id])
      flash[:error] = "Character could not be found."
      redirect_to characters_path and return
    end
  end

  def find_group
    return unless params[:group_id].present?
    @group = CharacterGroup.find_by_id(params[:group_id])
  end

  def require_own_character
    if @character.user_id != current_user.id
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
    gon.character_id = @character.try(:id) || ''
  end

  def save_character_with_extras
    Character.transaction do
      if template = @character.instance_variable_get('@template')
        template.save
        @character.template = template
      end
      if group = @character.instance_variable_get('@group')
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
end
