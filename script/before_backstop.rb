#!/usr/bin/env ruby
# frozen_string_literal: true

layout = ARGV[0]
user = User.find_by(username: "Kappa")

unless layout.nil?
  if layout == 'default'
    user.update!(layout: nil)
  else
    user.update!(layout: layout)
  end
end

# The unread reply from Kappa's seeded message thread (was id 4 until the import message became a Notification).
Message.find_by!(recipient: user, message: "Sample reply 2").update!(unread: true)

# db:seed only enqueues flat post generation (FlatPost.regenerate_all), which needs a Resque worker;
# render the missing flat posts here instead so the pages that read them work without one.
Post.where.missing(:flat_post).find_each { |missing| GenerateFlatPostJob.perform_now(missing.id) }

post = Post.find_by(id: 33)
post.mark_read(user, at_time: (post.replies.first.created_at - 5.seconds), force: true)

FlatPost.find_by!(post_id: 3).update!(updated_at: "2012-09-13 02:00:00")
NewsView.find_by(user: user)&.destroy!
Post.find_by(id: 2).mark_read(user, at_time: "2019-06-22 07:40:11", force: true)
ReportView.find_or_create_by!(user_id: 3).update!(read_at: 3.days.ago.to_date)

# The browser logs in through a signed user_id cookie, which is only valid for the secret_key_base of this checkout,
# so generate it here (backstop/engine_scripts/cookies.local.json is gitignored) instead of committing a fixed one.
jar = ActionDispatch::Request.new(Rails.application.env_config.merge('HTTP_HOST' => 'web')).cookie_jar
jar.signed[:user_id] = user.id
cookie = { domain: 'web', path: '/', name: 'user_id', value: jar[:user_id].to_s, httpOnly: false, secure: false, session: true, sameSite: 'Unset' }
Rails.root.join('backstop', 'engine_scripts', 'cookies.local.json').write("#{JSON.pretty_generate([cookie])}\n")
