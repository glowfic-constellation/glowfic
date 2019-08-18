#!/usr/bin/env ruby

wraith = ARGV[0] || 'wraith'
command = ARGV[1] || 'latest'

WRAITH_DIR = 'wraith'

user = User.find_by(username: "Kappa")

layouts = ['default', 'dark', 'iconless', 'starry', 'starrydark', 'starrylight', 'monochrome', 'river']

def run(layout, wraith, command)
  output = `#{wraith} #{command} #{WRAITH_DIR}/#{layout}`
  if $?.exitstatus.zero?
    puts "#{layout} successful"
  else
    index = output.index("WARN")
    if index.nil?
      puts output.lines("\n")[-10..-1].join
    else
      puts output.from(index)
    end
  end
end

layouts.each do |layout|
  if layout == 'default'
    user.update!(layout: nil)
  else
    user.update!(layout: layout)
  end
  Message.find_by(id: 4).update!(unread: true)
  post = Post.find_by(id: 33)
  post.mark_read(user, post.replies.first.created_at, true)
  FlatPost.find_by(post_id: 3).update!(updated_at: "2012-09-13 02:00:00")
  run(layout, wraith, command)
end

run('logged_out', wraith, command)
