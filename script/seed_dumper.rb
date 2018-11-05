require 'rails'

TABLES = {
  Icon: ['created_at', 'updated_at', 'has_gallery', 's3_key', 'credit'],
  Template: ['created_at', 'updated_at', 'description'],
  Character: ['created_at', 'updated_at', 'character_group_id', 'description'],
  CharacterAlias: ['created_at', 'updated_at'],
  Gallery: ['created_at', 'updated_at'],
  CharactersGallery: ['created_at', 'updated_at'],
  GalleriesIcon: ['created_at', 'updated_at'],
  Post: ['created_at', 'updated_at', 'tagged_at', 'edited_at', 'description', 'last_user_id', 'last_reply_id', 'authors_locked', 'privacy'],
  Reply: ['created_at', 'updated_at', 'reply_order', 'thread_id'],
  GalleryGroup: ['created_at', 'updated_at', 'description'],
  Setting: ['created_at', 'updated_at', 'description'],
  CharacterTag: ['created_at', 'updated_at'],
  GalleryTag: ['created_at', 'updated_at'],
  TagTag: ['created_at', 'updated_at', 'suggested'],
  PostTag: ['created_at', 'updated_at', 'suggested'],
}

MODELS = [Icon, Template, Character, CharacterAlias, Gallery, CharactersGallery, GalleriesIcon, Post, Reply, GalleryGroup, Setting, CharacterTag, GalleryTag, TagTag, PostTag]

FILES = {
  Icon: [Icon],
  Character: [Template, 'puts "Creating characters..."', Character, 'puts "Creating character aliases..."', CharacterAlias],
  Gallery: [Gallery, 'puts "Assigning galleries to characters..."', CharactersGallery, 'puts "Populating galleries with icons..."', GalleriesIcon],
  Post: [Post],
  Reply: [Reply],
  Tag: [GalleryGroup, Setting, 'puts "Assigning tags to characters..."', CharacterTag, 'puts "Assigning tags to galleries..."', GalleryTag, 'puts "Attaching settings to each other..."', TagTag, 'puts "Attaching tags to posts..."', PostTag]
}

def dump(model)
  puts "Dumping #{model.name}..."
  exclude = TABLES[model.name.to_sym].join(',')
  file = Rails.root.join('db', 'seeds', model.name.underscore + '.rb')
  `rake db:seed:dump MODEL=#{model.name} EXCLUDE=#{exclude} FILE=#{file}`
  file
end

def sort(file)
  size = `wc -l < #{file}`.chomp.to_i
  `head -n 1 #{file} > db/seeds/tmp`
  `sed -n '2,#{size - 1}p' #{file} | sort -V >> db/seeds/tmp`
  `tail -n 1 #{file} >> db/seeds/tmp`
  `mv -f db/seeds/tmp #{file}`
end

def clean(file, expand = false)
  sort(file)
  lines = []
  File.readlines(file).each do |line|
    line.gsub!(/}$/, "},")
    line.gsub!(/{id: [0-9]{1,3},/, "{")

    line.gsub!(", template_name: nil", "")
    line.gsub!(", screenname: nil", "")
    line.gsub!(", template_id: nil", "")
    line.gsub!(", default_icon_id: nil", "")
    line.gsub!(", pb: nil", "")
    line.gsub!(", added_by_group: false", "")
    line.gsub!(", section_order: 0}", "}")
    line.gsub!(", owned: false", "")
    line.gsub!(", section_id: nil", "")
    line.gsub!(", character_id: nil", "")
    line.gsub!(", character_alias_id: nil", "")
    line.gsub!(", icon_id: nil", "")
    if expand
      line.gsub!("{", "{\n   ")
      line.gsub!("}", "\n  }")
      line.gsub!(/([\d"]),/, "\\1,\n   ")
    else
      line.gsub!("{", "{")
      line.gsub!("}", " }")
    end
    line.chomp!
    lines << line
  end
  File.open(file, 'w') do |f|
    lines.each do |line|
      f.puts(line)
    end
  end
end

MODELS.each do |model|
  file = dump(model)
  expand = true if [Character, Post, Reply].include?(model)
  clean(file, expand)
end

FILES.each do |key, value|
  next if value.count == 1
  file = Rails.root.join('db', 'seeds', key.to_s.downcase + '.out')
  value.each do |part|
    if part.is_a?(String)
      File.open(file, 'a') do |f|
        f.puts ""
        f.puts part
      end
    else
      part_file = Rails.root.join('db', 'seeds', part.name.underscore + '.rb')
      `cat #{part_file} >> #{file}`
      `rm #{part_file}`
    end
  end
  `mv #{file} #{Rails.root.join('db', 'seeds', key.to_s.downcase + '.rb')}`
end
