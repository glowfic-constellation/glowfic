# frozen_string_literal: true
class TagsController < TaggableController
  def index
    @tags = TagSearcher.new.search(tag_name: params[:name], tag_type: params[:view], page: page)
    @post_counts = Post.visible_to(current_user).joins(post_tags: :tag).where(post_tags: { tag_id: @tags.map(&:id) })
    @post_counts = @post_counts.group('post_tags.tag_id').count
    @view = params[:view]
    @page_title = @view.present? ? @view.titlecase.pluralize : 'Tags'
    @tag_options = (Tag::TYPES - ['GalleryGroup']).sort.reverse.index_by(&:titlecase)
    use_javascript('tags/index')
  rescue InvalidTagType => e
    flash[:error] = e.api_error
    redirect_to tags_path
  end

  def update
    begin
      @tag.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@tag, action: 'updated', now: true, err: e)

      @page_title = "Edit Tag: #{@tag.name}"
      render :edit
    else
      flash[:success] = "Tag updated."
      redirect_to tag_path(@tag)
    end
  end

  def destroy
    begin
      @tag.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@tag, action: 'deleted', err: e)
      redirect_to tag_path(@tag)
    else
      flash[:success] = "Tag deleted."

      url_params = {}
      url_params[:page] = page if params[:page].present?
      url_params[:view] = params[:view] if params[:view].present?
      redirect_to tags_path(url_params)
    end
  end

  private

  def find_model
    return if (@tag = Tag.find_by(id: params[:id]))
    flash[:error] = "Tag could not be found."
    redirect_to tags_path
  end
end
