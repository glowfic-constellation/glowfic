class CharactersController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :facecasts]
  before_filter :find_character, :only => [:show, :edit, :update, :destroy, :icon]
  before_filter :find_group, :only => :index
  before_filter :require_own_character, :only => [:edit, :update, :destroy, :icon]
  before_filter :build_editor, :only => [:new, :create, :edit, :update]

  def index
    (return if login_required) unless params[:user_id].present?
    @user = current_user
    if params[:user_id]
      @user = User.find_by_id(params[:user_id])
      unless @user
        flash[:error] = "User could not be found."
        redirect_to users_path and return
      end
    end

    @characters = @user.characters.order('name asc')
  end

  def new
    @character = Character.new(template_id: params[:template_id])
  end

  def create
    @character = Character.new((params[:character] || {}).merge(user: current_user))
    unless verify_character_foreigns(@character)
      render :action => :new
      return
    end

    if @character.valid?
      save_character_with_extras
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      flash.now[:error] = "Your character could not be saved."
      render :action => :new
    end
  end

  def show
    @posts = @character.recent_posts(25, page)
  end

  def edit
  end

  def update
    @character.assign_attributes(params[:character])
    unless verify_character_foreigns(@character)
      render :action => :edit
      return
    end

    if @character.valid?
      save_character_with_extras
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      flash.now[:error] = "Your character could not be saved."
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
    chars = Character.where('pb is not null')
    @pbs = {}

    if params[:sort] == "name"
      chars.each do |character|
        key = character.template || character
        @pbs[key] ||= []
        @pbs[key] << character.pb
      end
    else
      chars.each do |character|
        @pbs[character.pb] ||= []
        @pbs[character.pb] << character unless character.template
        @pbs[character.pb] << character.template if character.template
      end
    end
  end

  private

  def find_character
    @character = Character.find_by_id(params[:id])

    unless @character
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
      flash[:error] = "That is not your character."
      redirect_to characters_path and return
    end
  end

  def build_editor
    faked = Struct.new(:name, :id)
    new_template = faked.new('— Create New Template —', 0)
    @templates = current_user.templates.order('name asc') + [new_template]
    new_group = faked.new('— Create New Group —', 0)
    @groups = current_user.character_groups.order('name asc') + [new_group]
    use_javascript('characters')
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
  
  def verify_character_foreigns(character)
    # template_id, gallery_ids and default_icon_id
    return unless character.present?
    if character.template.present? && character.template.user_id != current_user.id
      character.template = nil
      flash.now[:error] = "Template must be your own."
      return
    end
    if character.galleries.present? && character.galleries.detect {|g| g.user_id != current_user.id}
      flash.now[:error] = "Galleries must be your own."
      return
    end
    if character.default_icon.present? && character.default_icon.user_id != current_user.id
      character.default_icon = nil
      flash.now[:error] = "Default icon must be your own."
      return
    end
    character
  end
end
