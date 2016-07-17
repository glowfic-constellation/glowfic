class BlocksController < CrudController
  def index
    @page_title = "Blocked Users"
    @blocks = Block.where(blocking_user: current_user)
  end

  def new
    super
    @users = []
  end

  private

  def set_params(model)
    model.blocking_user = current_user
    model.blocked_user_id = params.fetch(:block, {})[:blocked_user_id]
  end

  def model_params
    params.fetch(:block, {}).permit(:block_interactions, :hide_me, :hide_them)
  end

  def editor_setup
    use_javascript('blocks')
    @options = {
      "Nothing"    => Block::NONE,
      "Just posts" => Block::POSTS,
      "Everything" => Block::ALL,
    }
  end
end
