# frozen_string_literal: true
class IndexesController < CrudController
  def index
    super
    @indexes = Index.order('id asc').paginate(per_page: 25, page: page)
  end

  def show
    super
    @sectionless = @index.posts.where(index_posts: {index_section_id: nil})
    @sectionless = @sectionless.ordered_by_index
    @sectionless = posts_from_relation(@sectionless, with_pagination: false, select: ', index_posts.description as index_description')
    @sectionless = @sectionless.select { |p| p.visible_to?(current_user) }
  end

  def destroy
    begin
      @index.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Index could not be deleted.",
        array: @index.errors.full_messages
      }
      redirect_to index_path(@index)
    else
      redirect_to indexes_path
      flash[:success] = "Index deleted."
    end
  end

  private

  def model_params
    params.fetch(:index, {}).permit(:name, :description, :privacy, :open_to_anyone)
  end

  def index_params
    params.fetch(:index, {}).permit(:name, :description, :privacy, :authors_locked)
  end

  def set_params(new_index)
    new_index.user = current_user
  end
end
