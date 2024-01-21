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
      render_errors(@block, action: 'create', now: true, msg: 'User could not be blocked')
      editor_setup
      @users = [@block.blocked_user].compact
      @page_title = 'Block User'
      render :new and return
    end

    flash[:success] = "User blocked."
    redirect_to blocks_path
  end

  def edit
    @page_title = 'Edit Block: ' + @block.blocked_user.username
  end

  def update
    unless @block.update(permitted_params)
      render_errors(@block, action: 'updated', now: true)
      editor_setup
      @page_title = 'Edit Block: ' + @block.blocked_user.username
      render :edit and return
    end

    flash[:success] = "Block updated."
    redirect_to blocks_path
  end

  def destroy
    begin
      @block.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@block, action: 'delete', msg: 'User could not be unblocked', err: e)
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
