require "spec_helper"

RSpec.feature "Favorites page", :type => :feature do
  scenario "User views normal favorites" do
    user = create(:user, username: "usert")
    create(:post, user: user, subject: "user post") # user_post
    post = create(:post, subject: "postt")
    continuity = create(:continuity, creator: user, name: "continuityt")
    create(:post, continuity: continuity, subject: "continuity post") # continuity_post
    create(:post, continuity: continuity, user: user, subject: "continuity user post") # continuity_user_post

    logged_in_user = login
    create(:favorite, user: logged_in_user, favorite: user)
    create(:favorite, user: logged_in_user, favorite: post)
    create(:favorite, user: logged_in_user, favorite: continuity)

    visit favorites_path

    expect(page).to have_text("Your Favorites")
    expect(page).not_to have_text("continuityt Continuity")
    expect(page).not_to have_text("usert User")
    expect(page).not_to have_text("postt Post")
    expect(page).to have_text("user post")
    expect(page).to have_text("continuity post")
    expect(page).to have_text("continuity user post") # TODO update favorite.type column

    click_link "Grouped »"

    expect(page).to have_text("Your Favorites")
    expect(page).to have_text("continuityt Continuity")
    expect(page).to have_text("usert User")
    expect(page).to have_text("postt Post")
    expect(page).not_to have_text("user post")
    expect(page).not_to have_text("continuity post")
    expect(page).not_to have_text("continuity user post")
  end
end
