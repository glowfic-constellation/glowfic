# frozen_string_literal: true
class IndexPostsController < GenericController
  before_action :find_index, only: [:new, :create]

  def new
    @index_post = IndexPost.new(index: index, index_section_id: params[:index_section_id])
    @page_title = "Add Posts to Index"
  end

  def create
    @csm = "Post added to index."
    @cfm = "Post could not be added to index"
    super
  end

  def edit
    @page_title = "Edit Post in Index"
  end

  def update
    super
    @page_title = "Edit Post in Index"
  end

  def destroy
    @dsm = "Post removed from index."
    @dfm = "Post could not be removed from index"
    super
  end

  private

  def find_index
    unless (id = params[:index_id])
      id = params.key?(:index_post) ? params[:index_post].fetch(:index_id, nil) : nil
    end

    unless (@index = Index.find_by(id: id))
      flash[:error] = "Index could not be found."
      redirect_to indexes_path and return
    end

    require_edit_permission(@index)
  end

  def permitted_params
    params.fetch(:index_post, {}).permit(:description, :index_id, :index_section_id, :post_id)
  end

  def require_edit_permission(index=@index_post.index)
    unless index.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this index."
      redirect_to index_path(@index_post.index) and return
    end
  end
  alias_method :require_destroy_permission, :require_edit_permission

  def editor_setup
    use_javascript('posts/index_post_new')
  end

  def model_name
    'Index post'
  end

  def model_class
    IndexPost
  end

  def set_model
    @index_post = @model
  end

  def create_redirect
    index_path(@index_post.index)
  end
  alias_method :update_redirect, :create_redirect
  alias_method :destroy_redirect, :create_redirect
  alias_method :destroy_failed_redirect, :create_redirect

  def models_path
    indexes_path
  end
  alias_method :invalid_redirect, :models_path
end
