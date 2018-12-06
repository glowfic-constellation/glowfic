#!/usr/bin/env ruby

wraith = ARGV[0] || 'wraith'
command = ARGV[1] || 'latest'

WRAITH_DIR = 'wraith'

user = User.find_by(username: "Kappa")

layouts = ['default', 'dark', 'iconless', 'starry', 'starrydark', 'starrylight', 'monochrome', 'river']

layouts.each do |layout|
  if layout == 'default'
    user.update!(layout: nil)
  else
    user.update!(layout: layout)
  end
  puts `#{wraith} #{command} wraith/#{layout}`
end

puts `#{wraith} #{command} wraith/logged_out`
