# frozen_string_literal: true
EXCLUDED_SCHEMA = {
  Icon: ['created_at', 'updated_at', 'has_gallery', 's3_key', 'credit'].freeze,
  Template: ['created_at', 'updated_at', 'description'].freeze,
  Character: ['created_at', 'updated_at', 'character_group_id', 'description'].freeze,
  CharacterAlias: ['created_at', 'updated_at'].freeze,
  Gallery: ['created_at', 'updated_at'].freeze,
  CharactersGallery: ['created_at', 'updated_at'].freeze,
  GalleriesIcon: ['created_at', 'updated_at'].freeze,
  Post: ['privacy', 'last_reply_id', 'last_user_id'].freeze,
  Reply: ['reply_order', 'thread_id'].freeze,
  ContentWarning: ['created_at', 'updated_at', 'description'].freeze,
  GalleryGroup: ['created_at', 'updated_at', 'description'].freeze,
  Setting: ['created_at', 'updated_at', 'description'].freeze,
  CharacterTag: ['created_at', 'updated_at'].freeze,
  GalleryTag: ['created_at', 'updated_at'].freeze,
  Tag::SettingTag => ['created_at', 'updated_at', 'suggested'].freeze,
  PostTag: ['created_at', 'updated_at', 'suggested'].freeze,
  'Audited::Audit': [].freeze,
  Post::Author => ['created_at', 'updated_at'].freeze,
  Message: ['created_at', 'updated_at'].freeze,
  Post::View => ['created_at', 'updated_at', 'ignored', 'notify_message', 'notify_email', 'warnings_hidden'].freeze,
}.freeze

MODELS = [
  Icon, Template, Character, CharacterAlias, Gallery, CharactersGallery, GalleriesIcon, Post, Reply, ContentWarning, GalleryGroup,
  Setting, CharacterTag, GalleryTag, Tag::SettingTag, PostTag, Post::View,
].freeze

FILES = {
  # Icon: [Icon],
  Character: [
    Template,
    'puts "Creating characters..."', Character,
    'puts "Creating character aliases..."', CharacterAlias
  ].freeze,
  Gallery: [
    Gallery,
    'puts "Assigning galleries to characters..."', CharactersGallery,
    'puts "Populating galleries with icons..."', GalleriesIcon
  ].freeze,
  Post: [
    Post,
    'puts "Setting up post views..."', Post::View,
    'puts "Queuing flat post generation (will not update until jobs are run)"', 'FlatPost.regenerate_all',
  ].freeze,
  # Reply: [Reply],
  Tag: [
    ContentWarning, GalleryGroup, Setting,
    'puts "Assigning tags to characters..."', CharacterTag,
    'puts "Assigning tags to galleries..."', GalleryTag,
    'puts "Attaching settings to each other..."', Tag::SettingTag,
    'puts "Attaching tags to posts..."', PostTag,
  ].freeze,
}.freeze

def dump(model)
  puts "Dumping #{model.name.titleize.pluralize(model.count)}..."
  exclude = EXCLUDED_SCHEMA[model.name.to_sym].join(',')
  file = Rails.root.join('db', 'seeds', model.name.demodulize.underscore + '.rb')
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

def clean(file, expand=false)
  sort(file)
  lines = []
  File.readlines(file).each do |line|
    line.gsub!(/}$/, "},")
    line.gsub!(/{id: [0-9]{1,3},/, "{")

    line.gsub!(", nickname: nil", "")
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
    line.gsub!(", description: \"\"", "")
    line.gsub!(", description: nil", "")
    if expand
      line.gsub!("}", ",}")
      line.gsub!("{", "{\n   ")
      line.gsub!(/([\d"]),(?!\})/, "\\1,\n   ")
      line.gsub!("}", "\n  }")
    else
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
  next if model.none?
  puts "#{model.count} #{model.name.titleize.pluralize(model.count)}"
  file = dump(model)
  expand = true if [Character, Post, Reply, Audited::Audit].include?(model)
  clean(file, expand)
end

FILES.each do |key, value|
  file = Rails.root.join('db', 'seeds', key.to_s.downcase + '.out')
  value.each do |part|
    if part.is_a?(String)
      File.open(file, 'a') do |f|
        f.puts ""
        f.puts part
      end
    else
      part_file = Rails.root.join('db', 'seeds', part.name.demodulize.underscore + '.rb')
      next unless part_file.exist?
      `cat #{part_file} >> #{file}`
      `rm #{part_file}`
    end
  end
  `mv #{file} #{Rails.root.join('db', 'seeds', key.to_s.downcase + '.rb')}`
end
