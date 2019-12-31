ContentWarning.create!([
  { name: "warning 1", type: "ContentWarning" },
  { name: "warning 2", type: "ContentWarning" },
  { name: "warning 3", type: "ContentWarning" },
])
GalleryGroup.create!([
  { name: "JokerSherlock (SS)", type: "GalleryGroup" },
])
Setting.create!([
  { name: "Earth", type: "Setting" },
  { name: "Sunnyverse", type: "Setting" },
  { name: "Nexus", type: "Setting" },
  { name: "Aurum", type: "Setting" },
  { name: "Harmonics", type: "Setting" },
  { name: "Quinn", type: "Setting" },
  { name: "Dreamward", type: "Setting" },
  { name: "Buffy", type: "Setting" },
  { name: "Eos", type: "Setting" },
])

puts "Assigning owners to tags..."
ActsAsTaggableOn::Tagging.create!([
  { tag_id: 4, taggable_id: 3, taggable_type: 'User', context: 'settings' },
  { tag_id: 6, taggable_id: 3, taggable_type: 'User', context: 'settings' },
  { tag_id: 9, taggable_id: 2, taggable_type: 'User', context: 'settings' },
  { tag_id: 10, taggable_id: 2, taggable_type: 'User', context: 'settings' },
  { tag_id: 12, taggable_id: 2, taggable_type: 'User', context: 'settings' },
])

puts "Assigning tags to characters..."
ActsAsTaggableOn::Tagging.create!([
  { taggable_id: 26, tag_id: 4, taggable_type: 'Character', context: 'gallery_groups' },
  { taggable_id: 10, tag_id: 8, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 12, tag_id: 11, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 14, tag_id: 10, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 15, tag_id: 5, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 16, tag_id: 5, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 17, tag_id: 8, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 18, tag_id: 10, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 19, tag_id: 13, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 20, tag_id: 6, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 21, tag_id: 5, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 22, tag_id: 5, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 26, tag_id: 7, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 27, tag_id: 7, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 28, tag_id: 7, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 29, tag_id: 5, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 30, tag_id: 8, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 31, tag_id: 13, taggable_type: 'Character', context: 'settings' },
  { taggable_id: 33, tag_id: 5, taggable_type: 'Character', context: 'settings' },
])

puts "Assigning tags to galleries..."
ActsAsTaggableOn::Tagging.create!([
  { taggable_id: 26, tag_id: 4, taggable_type: 'Gallery', context: 'gallery_groups' },
  { taggable_id: 28, tag_id: 4, taggable_type: 'Gallery', context: 'gallery_groups' },
  { taggable_id: 27, tag_id: 4, taggable_type: 'Gallery', context: 'gallery_groups' },
])

puts "Attaching settings to each other..."
ActsAsTaggableOn::Tagging.create!([
  { taggable_id: 6, tag_id: 12, taggable_type: 'Setting', context: 'settings' },
  { taggable_id: 12, tag_id: 5, taggable_type: 'Setting', context: 'settings' },
  { taggable_id: 8, tag_id: 5, taggable_type: 'Setting', context: 'settings' },
])

puts "Attaching tags to posts..."
ActsAsTaggableOn::Tagging.create!([
  { taggable_id: 12, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 8, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 9, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 10, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 11, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 4, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 3, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 5, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 6, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 7, tag_id: 5, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 12, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 8, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 9, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 10, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 11, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 13, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 14, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 15, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 16, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 17, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 18, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 19, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 20, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 21, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 22, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 23, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 24, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 25, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 26, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 27, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 28, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 29, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 30, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 31, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 4, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 3, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 5, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 6, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 7, tag_id: 13, taggable_type: 'Post', context: 'settings' },
  { taggable_id: 1, tag_id: 1, taggable_type: 'Post', context: 'content_warnings' },
  { taggable_id: 1, tag_id: 2, taggable_type: 'Post', context: 'content_warnings' },
  { taggable_id: 1, tag_id: 3, taggable_type: 'Post', context: 'content_warnings' },
  { taggable_id: 32, tag_id: 7, taggable_type: 'Post', context: 'settings' },
])
