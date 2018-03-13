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

Template.transaction do
  puts "Reassigning templates..."
  Template.order(:id).all.each_with_index do |template, i|
    exp_id = i + 1
    old_id = template.id
    puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
    next if old_id == exp_id
    new_id = copy_object(template, exp_id)
    update_models(Character, :template_id, old_id, new_id)
    template.destroy!
  end
end

Icon.transaction do
  puts "Reassigning icons..."
  Icon.order(:id).all.each_with_index do |icon, i|
    exp_id = i + 1
    old_id = icon.id
    puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
    next if old_id == exp_id
    new_id = copy_object(icon, exp_id)
    update_models(Character, :default_icon_id, old_id, new_id)
    update_models(GalleriesIcon, :icon_id, old_id, new_id)
    icon.destroy!
  end
end

Character.transaction do
  puts "Reassigning characters..."
  Character.order(:id).all.each_with_index do |char, i|
    exp_id = i + 1
    old_id = char.id
    puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
    next if old_id == exp_id
    new_id = copy_object(char, exp_id)
    update_models(CharactersGallery, :character_id, old_id, new_id)
    update_models(CharactersTag, :character_id, old_id, new_id)
    char.destroy!
  end
end

Gallery.transaction do
  puts "Reassigning galleries..."
  Gallery.order(:id).all.each_with_index do |gallery, i|
    exp_id = i + 1
    old_id = gallery.id
    puts "\tOld id: #{old_id}, Expected new id: #{exp_id}"
    next if old_id == exp_id
    new_id = copy_object(gallery, exp_id)
    update_models(CharactersGallery, :gallery_id, old_id, new_id)
    update_models(GalleriesIcon, :gallery_id, old_id, new_id)
    update_models(GalleryTag, :gallery_id, old_id, new_id)
    gallery.destroy!
  end
end

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
