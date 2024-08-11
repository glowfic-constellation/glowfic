# Autogenerated by the db:seed:dump task
# Do not hesitate to tweak this to your needs

puts "Seeding database..."

puts "Creating users..."
marri = User.create!(
  username: 'Marri', password: 'nikari', email: "dummy1@example.com", default_editor: 'html',
  unread_opened: true, role_id: Permissible::ADMIN, default_view: 'list', layout: 'starrylight',
  moiety_name: 'Red', moiety: 'AA0000', hide_warnings: true, ignore_unread_daily_report: true,
  visible_unread: true, created_at: "2015-10-05 19:39:00",
)

alicorn = User.create!(username: 'Alicorn', password: 'alicorn', email: "dummy2@example.com", created_at: "2015-10-05 19:39:00")

kappa = User.create!(
  username: 'Kappa', password: 'pythbox', email: "dummy3@example.com", role_id: Permissible::IMPORTER,
  visible_unread: true, created_at: "2015-10-05 19:39:00",
)

aestrix = User.create!(username: 'Aestrix', password: 'aestrix', email: "dummy4@example.com", created_at: "2015-11-26 7:59:00")

throne = User.create!(
  username: 'Throne3d', password: 'throne3d', email: "dummy5@example.com", role_id: Permissible::MOD,
  created_at: "2016-02-22 14:48:00",
)

teceler = User.create!(
  username: 'Teceler', password: 'teceler', email: "dummy6@example.com", role_id: Permissible::MOD,
  default_editor: 'html', layout: 'starrydark', ignore_unread_daily_report: true, created_at: "2015-12-17 19:48:00",
)

User.update_all(tos_version: 20181109) # rubocop:disable Rails/SkipsModelValidations

puts "Creating avatars..."
Icon.create!([
  { user_id: 1, url: "https://pbs.twimg.com/profile_images/482603626/avatar.png", keyword: "avatar" },
  { user_id: 2, url: "https://33.media.tumblr.com/avatar_ddf517a261d8_64.png", keyword: "avatar" },
  { user_id: 3, url: "https://i.imgur.com/OJSBRcp.jpg", keyword: "avatar" },
  { user_id: 5, url: "https://i.imgur.com/7aXnrK1.jpg", keyword: "avatar" },
  { user_id: 6, url: "https://i.imgur.com/WA1r2Fu.png", keyword: "avatar" },
])
marri.update!(avatar_id: 1)
alicorn.update!(avatar_id: 2)
kappa.update!(avatar_id: 3)
throne.update!(avatar_id: 4)
teceler.update!(avatar_id: 5)

puts "Creating continuities..."
Board.create!([
  { name: 'Effulgence', creator: alicorn, writers: [kappa] },
  { name: 'Witchlight', creator: alicorn, writers: [marri] },
  { name: 'Sandboxes', creator: marri, pinned: true, authors_locked: false },
  { name: 'Site testing', creator: marri, authors_locked: false },
  { name: 'Pixiethreads', creator: kappa, writers: [aestrix] },
  { name: 'Incandescence', creator: alicorn, writers: [aestrix] },
])

puts "Creating sections..."
BoardSection.create!([
  { board_id: 1, name: "make a wish", status: 1, section_order: 0 },
  { board_id: 1, name: "hexes", status: 1, section_order: 1 },
  { board_id: 1, name: "parable of the talents", status: 1, section_order: 2 },
  { board_id: 1, name: "golden opportunity", status: 0, section_order: 3 },
])

puts "Creating news posts..."
News.create!([
  { user_id: 1, content: "News Post 1", created_at: "2019-08-18 21:19:27", updated_at: "2019-08-18 21:19:27" },
  { user_id: 1, content: "News Post 2", created_at: "2019-08-18 21:19:27", updated_at: "2019-08-18 21:19:27" },
])

puts "Creating icons..."
load Rails.root.join('db', 'seeds', 'icon.rb')

puts "Creating templates..."
load Rails.root.join('db', 'seeds', 'character.rb')

puts "Creating galleries..."
load Rails.root.join('db', 'seeds', 'gallery.rb')

puts "Creating posts..."
load Rails.root.join('db', 'seeds', 'post.rb')

puts "Creating replies..."
load Rails.root.join('db', 'seeds', 'reply.rb')

puts "Queuing flat post generation (will not update until jobs are run)"
FlatPost.regenerate_all

puts "Creating tags..."
load Rails.root.join('db', 'seeds', 'tag.rb')

puts "Creating audits..."
load Rails.root.join('db', 'seeds', 'audit.rb')

puts "Creating messages..."
Message.create!([
  { sender_id: 1, recipient_id: 3, subject: "Test Message", message: "Sample text", created_at: "2019-08-19 04:10:00" },
  { sender_id: 3, recipient_id: 1, parent_id: 2, thread_id: 1, message: "Sample reply", unread: false, created_at: "2019-08-19 04:15:00" },
  { sender_id: 1, recipient_id: 3, parent_id: 3, thread_id: 1, message: "Sample reply 2", created_at: "2019-08-19 04:20:00" },
])

puts "Creating notifications..."
Notification.create!([
  { user_id: 3, post_id: 32, notification_type: :import_success },
  { user_id: 3, post_id: nil, notification_type: :import_fail, error_msg: 'Unrecognized username: wild_pegasus_appeared' },
])

puts "Creating favorites..."
Favorite.create!([
  { user_id: 3, favorite_id: 1, favorite_type: "Post" },
  { user_id: 3, favorite_id: 1, favorite_type: "Board" },
  { user_id: 3, favorite_id: 1, favorite_type: "User" },
])
