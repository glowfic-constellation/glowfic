# Visits pages in a real browser to catch JavaScript errors that no behavioural spec would notice
# (the :js hook in spec/support/js_error_helper.rb also fails any example on an uncaught error; the
# explicit check here names the page).
RSpec.describe "Page smoke test", :js do
  let(:public_paths) do
    %i(
      root_path login_path tos_path privacy_path contact_path dmca_path contribute_path news_index_path
      users_path search_users_path posts_path search_posts_path continuities_path search_continuities_path
      tags_path indexes_path reports_path characters_path facecasts_characters_path galleries_path
      search_galleries_path search_templates_path search_characters_path search_replies_path
      new_password_reset_path
    ).map { |name| public_send(name) }
  end

  let(:member_paths) do
    %i(
      new_post_path unread_posts_path owed_posts_path hidden_posts_path notifications_path messages_path
      new_message_path new_character_path new_gallery_path new_template_path new_continuity_path
      new_board_section_path new_index_path new_index_section_path new_index_post_path blocks_path
      new_block_path favorites_path search_bookmarks_path
    ).map { |name| public_send(name) }
  end

  # returns the JavaScript errors seen, by path (empty when every page was clean)
  def js_errors_by_page(paths)
    errors_by_path = paths.index_with do |path|
      visit path
      collected_js_errors.uniq
    end
    errors_by_path.reject { |_, errors| errors.empty? }
  end

  scenario "public pages, logged out" do
    expect(js_errors_by_page(public_paths)).to be_empty
  end

  scenario "public and member pages, logged in" do
    login
    expect(js_errors_by_page(public_paths + member_paths)).to be_empty
  end

  scenario "pages with records, logged in" do
    user = login
    board = create(:board, creator: user)
    post = create(:post, user: user, board: board)
    create_list(:reply, 2, post: post, user: user)
    character = create(:character, user: user)
    gallery = create(:gallery, user: user)
    template = create(:template, user: user)
    reply = post.replies.first

    expect(js_errors_by_page([
      post_path(post), stats_post_path(post), history_post_path(post), edit_post_path(post), reply_path(reply),
      edit_reply_path(reply), continuity_path(board), edit_continuity_path(board), user_path(user),
      edit_user_path(user), profile_edit_user_path(user), user_characters_path(user), user_galleries_path(user),
      character_path(character), edit_character_path(character), gallery_path(gallery), edit_gallery_path(gallery),
      add_gallery_path(gallery), template_path(template), edit_template_path(template), report_path('daily'),
    ])).to be_empty
  end
end
