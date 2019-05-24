# frozen_string_literal: true
class IndexSectionsController < GenericController
  before_action :find_index, only: [:new, :create]

  def new
    super
  end

  def create
    section_name = params[:index_section].fetch(:name, nil)
    @csm = "New section, #{section_name}, created for #{@index.name}."
    super
  end

  private

  def find_index
    unless (id = params[:index_id])
      id = params.key?(:index_section) ? params[:index_section].fetch(:index_id, nil) : nil
    end

    unless (@index = Index.find_by(id: id))
      flash[:error] = "Index could not be found."
      redirect_to indexes_path and return
    end

    require_edit_permission(@index)
  end

  def require_edit_permission(index=@section.index)
    unless index.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this index."
      redirect_to index_path(index)
    end
  end
  alias_method :require_delete_permission, :require_edit_permission

  def permitted_params
    params.fetch(:index_section, {}).permit(:name, :description, :index_id)
  end

  def set_model
    @section = @model
  end

  def model_name
    'Index section'
  end

  def model_class
    IndexSection
  end

  def create_redirect
    index_path(@section.index)
  end
  alias_method :update_redirect, :create_redirect
  alias_method :destroy_redirect, :create_redirect
  alias_method :destroy_failed_redirect, :create_redirect

  def models_path
    indexes_path
  end
  alias_method :invalid_redirect, :models_path
end
