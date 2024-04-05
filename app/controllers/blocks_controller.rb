class BlocksController < ApplicationController
  before_action :login_required
  before_action :find_model, only: [:edit, :update, :destroy]
  before_action :require_permission, only: [:edit, :update, :destroy]
  before_action :editor_setup, only: [:new, :edit]

  def index
    @page_title = t('.title')
    @blocks = Block.where(blocking_user: current_user)
  end

  def new
    @page_title = t('.title')
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
      render_errors(@block, action: 'create', now: true, msg: t('.failure'))
      editor_setup
      @users = [@block.blocked_user].compact
      @page_title = '.new.title'
      render :new and return
    end

    flash[:success] = t('.success')
    redirect_to blocks_path
  end

  def edit
    @page_title = t('.title', name: @block.blocked_user.username)
  end

  def update
    unless @block.update(permitted_params)
      render_errors(@block, action: 'updated', now: true)
      editor_setup
      @page_title = t('.title', name: @block.blocked_user.username)
      render :edit and return
    end

    flash[:success] = t('.success')
    redirect_to blocks_path
  end

  def destroy
    begin
      @block.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@block, action: 'delete', msg: t('.failure'), err: e)
    else
      flash[:success] = t('.success')
    end
    redirect_to blocks_path
  end

  private

  def permitted_params
    params.fetch(:block, {}).permit(:block_interactions, :hide_me, :hide_them)
  end

  def require_permission
    return if @block.editable_by?(current_user)
    flash[:error] = t('.errors.not_found') # Return the same error message as if it didn't exist
    redirect_to blocks_path
  end

  def find_model
    return if (@block = Block.find_by(id: params[:id]))
    flash[:error] = t('.errors.not_found')
    redirect_to blocks_path
  end

  def editor_setup
    use_javascript('blocks')
    @options = {
      t('.options.none')  => :none,
      t('.options.posts') => :posts,
      t('.options.all')   => :all,
    }
  end
end
