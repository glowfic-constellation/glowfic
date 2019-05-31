class BlocksController < ApplicationController
  before_action :login_required
  before_action :find_block, only: [:edit, :update, :destroy]
  before_action :require_permission, only: [:edit, :update, :destroy]
  before_action :editor_setup, only: [:new, :edit]

  def index
    @page_title = "Blocked Users"
    @blocks = Block.where(blocking_user: current_user)
  end

  def new
    @page_title = "Block User"
    @block = Block.new
    @block.blocking_user = current_user
    @users = []
  end

  def create
    @block = Block.new(permitted_params)
    @block.blocking_user = current_user
    @block.blocked_user_id = params.fetch(:block, {})[:blocked_user_id]

    if @block.save
      flash[:success] = "User blocked!"
      redirect_to blocks_path
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "User could not be blocked."
      flash.now[:error][:array] = @block.errors.full_messages
      editor_setup
      @users = [@block.blocked_user].compact
      @page_title = 'Block User'
      render :new
    end
  end

  def edit
    @page_title = 'Edit Block'
    @page_title += ": #{@block.blocked_user.username}" unless @block.user.deleted?
  end

  def update
    if @block.update(permitted_params)
      flash[:success] = "Block updated!"
      redirect_to blocks_path
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Block could not be saved."
      flash.now[:error][:array] = @block.errors.full_messages
      editor_setup
      @page_title = 'Edit Block'
      @page_title += ": #{@block.blocked_user.username}" unless @block.user.deleted?
      render :edit
    end
  end

  def destroy
    if @block.destroy
      flash[:success] = "User unblocked."
    else
      flash[:error] = {}
      flash[:error][:message] = "User could not be unblocked."
      flash[:error][:array] = @block.errors.full_messages
    end
    redirect_to blocks_path
  end

  private

  def permitted_params
    params.fetch(:block, {}).permit(:block_interactions, :hide_me, :hide_them)
  end

  def require_permission
    unless @block.editable_by?(current_user)
      flash[:error] = "Block could not be found." # Return the same error message as if it didn't exist
      redirect_to blocks_path and return
    end
  end

  def find_block
    unless (@block = Block.find_by(id: params[:id]))
      flash[:error] = "Block could not be found."
      redirect_to blocks_path and return
    end
  end

  def editor_setup
    use_javascript('blocks')
    @options = {
      "Nothing" => Block::NONE,
      "Just posts" => Block::POSTS,
      "Everything" => Block::ALL,
    }
  end
end
