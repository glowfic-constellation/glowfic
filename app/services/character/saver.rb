class Character::Saver < Generic::Saver
  attr_reader :character

  def initialize(character, user:, params:)
    super
    @character = character
    @settings = process_tags(Setting, :character, :setting_ids)
    @gallery_groups = process_tags(GalleryGroup, :character, :gallery_group_ids)
  end

  private

  def build
    build_template
  end

  def save!
    Character.transaction do
      @character.assign_attributes(permitted_params)
      @character.settings = process_tags(Setting, :character, :setting_ids)
      @character.gallery_groups = process_tags(GalleryGroup, :character, :gallery_group_ids)
      @character.save!
    end
  end

  def build_template
    return unless @params[:new_template].present? && @character.user == @user
    @character.build_template unless @character.template
    @character.template.user = @user
  end

  def process_tags(klass, obj_param, id_param)
    ids = @params.fetch(obj_param, {}).fetch(id_param, [])
    processer = Tag::Processer.new(ids, klass: klass, user: @user)
    processer.process
  end

  def permitted_params
    permitted = [
      :name,
      :nickname,
      :screenname,
      :template_id,
      :pb,
      :description,
      :retired,
      :npc,
      :cluster,
      :audit_comment,
      ungrouped_gallery_ids: [],
    ]
    if @character.user == @user
      permitted.last[:template_attributes] = [:name, :id]
      permitted.insert(0, :default_icon_id)
    end
    @params.fetch(:character, {}).permit(permitted)
  end
end
