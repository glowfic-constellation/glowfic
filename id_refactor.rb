Arrangements = {
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
    CharacterTag: :character_id,
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
  },
  Board: {
    Post: :board_id,
    BoardSection: :board_id
  },
  BoardSection: {
    Post: :section_id
  },
  Post: {
    Reply: :post_id,
    PostTag: :post_id,
    PostAuthor: :post_id,
    PostView: :post_id,
  }
}

def update_models(model, key, old_id, new_id)
  model = Reply.unscoped if model == Reply
  model.where(key => old_id).find_each do |object|
    object.update_columns(key => new_id)
  end
end

def copy_object(object, exp_id)
  copy = object.dup
  copy.id = exp_id
  #object.delete
  copy.save!
  copy.id
end

def check_object(object, model, exp_id)
  old_id = object.id
  puts "\tOld id: #{old_id}, New id: #{exp_id}"
  return if old_id == exp_id
  new_id = copy_object(object, exp_id)
  symbol = model.to_s.to_sym
  if Arrangements.key?(symbol)
    Arrangements[symbol].each do |key, value|
      puts "\t\t Updating #{key} with new #{value}, #{exp_id}..."
      update_models(key.to_s.constantize, value, old_id, new_id)
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

Reply.auditing_enabled = false
Post.auditing_enabled = false
iterate_model(Template)
iterate_model(Icon)
iterate_model(Character)
iterate_model(Gallery)
Tag.transaction do
  unless Tag.order(:type, :id).pluck(:id) == Tag.order(:id).pluck(:id)
    puts "Offsetting tags..."
    Setting.order(:id).all.each_with_index do |tag, i|
      check_object(tag, Setting, 1000+i)
    end
    GalleryGroup.order(:id).all.each_with_index do |tag, i|
      check_object(tag, GalleryGroup, 2000+i)
    end
  end
  puts "Consolidating tags..."
  Tag.order(:type, :id).all.each_with_index do |tag, i|
    check_object(tag, tag.class, i+1)
  end
end
iterate_model(CharactersGallery)
iterate_model(GalleriesIcon)
iterate_model(CharacterTag)
iterate_model(GalleryTag)
iterate_model(BoardSection)
iterate_model(Post)
