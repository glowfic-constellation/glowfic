class CharactersController < ApplicationController
  before_filter :login_required, :except => :show
  before_filter :find_character, :only => [:show, :edit, :update, :destroy, :icon]
  before_filter :require_own_character, :only => [:edit, :update, :destroy, :icon]
  before_filter :build_editor, :only => [:new, :create, :edit, :update]

  def index
    @user = current_user
    if params[:user_id]
      @user = User.find_by_id(params[:user_id])
      unless @user
        flash[:error] = "User could not be found."
        redirect_to users_path
      end
    end

    @characters = @user.characters.order('name asc')
  end

  def new
    @character = Character.new(template_id: params[:template_id])
  end

  def create
    @character = Character.new(params[:character].merge(user: current_user))

    if @character.template_id == 0
      template = Template.new(user: current_user, name: params[:character][:template_name])
      unless template.valid? && @character.valid?
        flash.now[:error] = "Your character could not be saved."
        render :action => :new and return
      end
      success = Character.transaction do
        template.save
        @character.template = template
        @character.save
      end
      if success
        flash[:success] = "Character saved successfully."
        redirect_to character_path(@character)
      else
        @character.template_id = 0
        flash.now[:error] = "Your character could not be saved."
        render :action => :new
      end
    elsif @character.save
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      flash.now[:error] = "Your character could not be saved."
      render :action => :new
    end
  end

  def show
  end

  def edit
    use_javascript('characters')
    gon.character_id = @character.id
  end

  def update
    if @character.update_attributes(params[:character])
      flash[:success] = "Character saved successfully."
      redirect_to character_path(@character)
    else
      use_javascript('characters')
      gon.character_id = @character.id
      flash.now[:error] = "Your character could not be saved."
      render :action => :edit
    end
  end

  def icon
    icon = Icon.find_by_id(params[:icon_id])
    @character.update_attributes(default_icon: icon) if icon
    render :json => {}
  end

  def destroy
    @character.destroy
    flash[:success] = "Character deleted successfully."
    redirect_to characters_path
  end

  private

  def find_character
    @character = Character.find_by_id(params[:id])

    unless @character
      flash[:error] = "Character could not be found."
      redirect_to characters_path and return
    end
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
    @templates = current_user.templates + [new_template]
    use_javascript('characters')
    gon.character_id = @character.try(:id) || ''
  end
end
