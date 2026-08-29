#!/usr/bin/env ruby
# Script to generate screenshots of all themes on continuity and thread pages.
# Run with: bundle exec rspec spec/screenshot_themes.rb
#
# Produces screenshots in tmp/theme_screenshots/

require 'rails_helper'

THEMES = {
  # name => layout value
  'Default' => nil,
  'Dark' => 'dark',
  'Iconless' => 'iconless',
  'Starry' => 'starry',
  'Starry Dark' => 'starrydark',
  'Starry Light' => 'starrylight',
  'Monochrome' => 'monochrome',
  'Milky River' => 'river',
}.freeze

AUTO_THEMES = {
  'Default (Auto)' => 'auto_default',
  'Starry (Auto)' => 'auto_starry',
  'Starry Light (Auto)' => 'auto_starrylight',
  'Monochrome (Auto)' => 'auto_monochrome',
  'Milky River (Auto)' => 'auto_river',
  'Iconless (Auto)' => 'auto_iconless',
}.freeze

RSpec.describe "Theme screenshots", type: :system, js: true do
  let(:screenshot_dir) { Rails.root.join('tmp', 'theme_screenshots') }

  let(:user) { create(:user, password: 'knownpass') }
  let(:board) { create(:board, creator: user, name: "Example Continuity") }
  let!(:post_obj) do
    Audited.audit_class.as_user(user) do
      post = create(:post,
        user: user,
        board: board,
        subject: "Example Thread",
        content: "<p>This is an example post with <b>bold</b> and <i>italic</i> text.</p><blockquote>A blockquote for testing color.</blockquote>",
      )
      create(:reply, post: post, user: user, content: "<p>A reply to test the thread view styling.</p>")
      create(:reply, post: post, user: user, content: "<p>Another reply with <a href='#'>a link</a> for contrast testing.</p>")
      post
    end
  end

  before(:all) do
    FileUtils.mkdir_p(Rails.root.join('tmp', 'theme_screenshots'))
  end

  def set_color_scheme(scheme)
    page.driver.browser.execute_cdp(
      'Emulation.setEmulatedMedia',
      features: [{ name: 'prefers-color-scheme', value: scheme }],
    )
  end

  def take_themed_screenshot(name, path)
    slug = name.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
    filename = screenshot_dir.join("#{slug}_#{path.tr('/', '_')}.png")
    page.save_screenshot(filename)
    puts "  Saved: #{filename}"
  end

  def login_with_theme(layout)
    user.update!(layout: layout)
    visit root_path
    fill_in "Username", with: user.username
    fill_in "Password", with: 'knownpass'
    click_button "Log in"
  end

  THEMES.each do |name, layout|
    it "screenshots #{name} theme" do
      login_with_theme(layout)

      # Continuity page
      visit continuity_path(board)
      take_themed_screenshot(name, "continuity")

      # Thread page
      visit post_path(post_obj)
      take_themed_screenshot(name, "thread")
    end
  end

  AUTO_THEMES.each do |name, layout|
    it "screenshots #{name} in light mode" do
      login_with_theme(layout)
      set_color_scheme('light')

      visit continuity_path(board)
      take_themed_screenshot("#{name} light", "continuity")

      visit post_path(post_obj)
      take_themed_screenshot("#{name} light", "thread")
    end

    it "screenshots #{name} in dark mode" do
      login_with_theme(layout)
      set_color_scheme('dark')

      visit continuity_path(board)
      take_themed_screenshot("#{name} dark", "continuity")

      visit post_path(post_obj)
      take_themed_screenshot("#{name} dark", "thread")
    end
  end
end
