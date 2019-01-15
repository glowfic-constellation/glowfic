class Gallery::Saver < Generic::Saver
  attr_reader :gallery

  private

  def save!
    Gallery.transaction do
      @model.gallery_groups = process_tags(GalleryGroup, :gallery, :gallery_group_ids)
      @model.save!
    end
  end

  def process_tags(klass, obj_param, id_param)
    ids = @params.fetch(obj_param, {}).fetch(id_param, [])
    processer = Tag::Processer.new(ids, klass: klass, user: @user)
    processer.process
  end

  def permitted_params
    @params.fetch(:gallery, {}).permit(
      :name,
      galleries_icons_attributes: [
        :id,
        :_destroy,
        icon_attributes: [:url, :keyword, :credit, :id, :_destroy, :s3_key]
      ],
      icon_ids: [],
      ungrouped_gallery_ids: [],
    )
  end
end
