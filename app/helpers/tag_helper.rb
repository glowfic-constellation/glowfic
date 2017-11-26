module TagHelper
  def delete_path(tag)
    url_params = {}
    url_params[:page] = page if params[:page].present?
    url_params[:view] = @view if @view.present?
    tag_path(tag, url_params)
  end

  def tag_select(obj, form, assoc, opts={})
    attr_name = assoc.to_s.singularize + "_ids"
    collection = obj.send(assoc) # form.object != obj
    ids = collection.map(&:id_for_select)

    form.select(
      attr_name,
      options_from_collection_for_select(collection, :id_for_select, :name, ids),
      {},
      {multiple: true}.merge(opts)
    )
  end
end
