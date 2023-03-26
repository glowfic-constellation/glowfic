class BlocksController < ApplicationController
  before_action :login_required
  before_action :find_model, only: [:edit, :update, :destroy]
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
    @block.blocked_user_id = params.fetch(:block, {})[:blocked_user_id]
    @users = [@block.blocked_user].compact
  end

  def create
    @block = Block.new(permitted_params)
    @block.blocking_user = current_user
    @block.blocked_user_id = params.fetch(:block, {})[:blocked_user_id]

    unless @block.save
      flash.now[:error] = {
        message: "User could not be blocked.",
        array: @block.errors.full_messages,
      }
      editor_setup
      @users = [@block.blocked_user].compact
      @page_title = 'Block User'
      render :new and return
    end

    flash[:success] = "User blocked!"
    redirect_to blocks_path
  end

  def edit
    @page_title = "Edit Block: #{@block.blocked_user.username}"
  end

  def update
    unless @block.update(permitted_params)
      flash.now[:error] = {
        message: "Block could not be saved.",
        array: @block.errors.full_messages,
      }
      editor_setup
      @page_title = "Edit Block: #{@block.blocked_user.username}"
      render :edit and return
    end

    flash[:success] = "Block updated!"
    redirect_to blocks_path
  end

  def destroy
    begin
      @block.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "User could not be unblocked.",
        array: @block.errors.full_messages,
      }
    else
      flash[:success] = "User unblocked."
    end
    redirect_to blocks_path
  end

  private

  def permitted_params
    params.fetch(:block, {}).permit(:block_interactions, :hide_me, :hide_them)
  end

  def require_permission
    return if @block.editable_by?(current_user)
    flash[:error] = "Block could not be found." # Return the same error message as if it didn't exist
    redirect_to blocks_path
  end

  def find_model
    return if (@block = Block.find_by(id: params[:id]))
    flash[:error] = "Block could not be found."
    redirect_to blocks_path
  end

  def editor_setup
    use_javascript('blocks')
    @options = {
      "Nothing"    => :none,
      "Just posts" => :posts,
      "Everything" => :all,
    }
  end
end
