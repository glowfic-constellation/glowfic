@arrangements = {
  Template: {
    Character: :template_id,
  },
  Icon: {
    Character: :default_icon_id,
    GalleriesIcon: :icon_id,
    Reply: :icon_id,
    Post: :icon_id,
    User: :avatar
  },
  Character: {
    CharactersGallery: :character_id,
    CharacterTag: :charater_id,
    Reply: :character_id,
    Post: :character_id
  },
  Gallery: {
    CharactersGallery: :gallery_id,
    GalleriesIcon: :gallery_id,
    GalleryTag: :gallery_id
  },
  Setting: {
    CharacterTag: :tag_id,
    PostTag: :tag_id
  },
  GalleryGroup: {
    CharacterTag: :tag_id,
    GalleryTag: :tag_id
  }
}

def update_models(model, key, old_id, new_id)
  model.where(key => old_id).find_each do |object|
    object.update(key => new_id)
  end
end

def copy_object(object, exp_id)
  copy = object.dup
  copy.id = exp_id
  copy.save!
  copy.id
end

def check_object(object, model, exp_id)
  old_id = object.id
  puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
  return if old_id == exp_id
  new_id = copy_object(object, exp_id)
  if @arrangements.key?(model)
    @arrangements[model].for_each do |key, value|
      puts "\t\t Updating #{key} with new #{value}, #{exp_id}..."
      update_models(key, value, old_id, new_id)
    end
  end
  object.destroy!
end

def iterate_model(model)
  model.transaction do
    puts "Reassigning #{model}s..."
    model.order(:id).all.each_with_index do |object, i|
      check_object(object, model, i + 1)
    end
  end
end

iterate_model(Template)
iterate_model(Icon)
iterate_model(Character)
iterate_model(Gallery)
Tag.transaction do
  puts "Reassigning tags..."
  Tag.for_each_with_index do |_n, i|
    exp_id = i + 1
    Setting.order(:id).all.each do |tag|
      check_object(tag, Setting, exp_id)
    end
    GalleryGroup.order(:id).all.each do |tag|
      check_object(tag, GalleryGroup, exp_id)
    end
  end
end
iterate_model(CharactersGallery)
iterate_model(GalleriesIcon)
iterate_model(CharacterTag)
iterate_model(GalleryTag)
