module TagHelper
  def delete_path(tag)
    url_params = {}
    url_params[:page] = page if params[:page].present?
    url_params[:view] = @view if @view.present?
    tag_path(tag, url_params)
  end
end
