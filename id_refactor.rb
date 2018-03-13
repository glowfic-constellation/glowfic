arrangements = {
  Template: {
    Character: :template_id,
  },
  Icon: {
    Character: :default_icon_id,
    GalleriesIcon: :icon_id
  },
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

def iterate_model(model)
  model.transaction do
    puts "Reassigning #{model.pluralize}..."
    model.order(:id).all.each_with_index do |object, i|
      exp_id = i + 1
      old_id = object.id
      puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
      next if old_id == exp_id
      new_id = copy_object(object, exp_id)
      arrangements[model].for_each do |key, value|
        update_models(key, value, old_id, new_id)
      end
      object.destroy!
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
    GalleryGroup.order(:id).all.each do |tag|
      old_id = tag.id
      puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
      next if old_id == exp_id
      new_id = copy_object(tag, exp_id)
      update_models(CharactersTag, :tag_id, old_id, new_id)
      update_models(GalleryTag, :tag_id, old_id, new_id)
      tag.destroy!
    end
    Setting.order(:id).all.each do |tag|
      exp_id = i + 1
      old_id = tag.id
      puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
      next if old_id == exp_id
      new_id = copy_object(tag, exp_id)
      update_models(CharactersTag, :tag_id, old_id, new_id)
      tag.destroy!
    end
  end
end
