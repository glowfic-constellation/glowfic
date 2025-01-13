RSpec.describe "Editing replies" do
  def find_reply_on_page(reply)
    find('.post-reply') { |x| x.has_selector?('a', id: "reply-#{reply.id}") }
  end

  scenario "Logged-out user tries to edit a reply" do
    reply = create(:reply)

    visit reply_path(reply)
    within(find_reply_on_page(reply)) do
      expect(page).to have_no_link('Edit')
    end

    visit edit_reply_path(reply)
    expect(page).to have_selector('.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
    expect(page).to have_no_selector('#post-editor')
  end

  scenario "User edits a reply" do
    user = create(:user, password: known_test_password)
    reply = create(:reply, user: user, content: 'example text')

    login(user, known_test_password)

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      click_button 'submit_button'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply updated.')
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'other text')
    end
  end

  scenario "User edits a reply with preview" do
    user = create(:user, password: known_test_password)
    reply = create(:reply, user: user, content: 'example text')

    login(user, known_test_password)

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      click_button 'Preview'
    end

    # verify preview, change again
    expect(page).to have_no_selector('.error')
    expect(page).to have_no_selector('.success')
    expect(page).to have_selector('.content-header', exact_text: reply.post.subject)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      expect(page).to have_selector('.post-content', exact_text: 'other text')
    end

    within('#post-editor') do
      expect(page).to have_field('reply_content', with: 'other text')
      fill_in 'reply_content', with: 'third text'
      click_button 'submit_button'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply updated.')
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'third text')
    end
  end

  context "Using the multi reply editor" do
    scenario "to split a reply", :js do
      user = login
      user.update!(default_editor: 'html')
      reply = create(:reply, user: user, content: 'example text', editor_mode: 'html')
      create(:reply, user: user, post: reply.post, content: 'example text 2')

      visit reply_path(reply)
      expect(page).to have_selector('.post-container', count: 3)
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end

      # add two extra replies
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
      expect(page).to have_no_selector('.post-container')
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end

      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Editing reply and adding more')
      expect(page).to have_selector('.post-container', count: 1)
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
        click_button 'Add More Replies'
      end

      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Editing reply and adding more')
      expect(page).to have_selector('.post-container', count: 2)
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 3'
        click_button 'Save All'
      end

      # All replies should be there in the right order
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.success', exact_text: 'Reply updated.')
      expect(page).to have_selector('.post-container', count: 5)
      all_containers = page.find_all(".post-container")
      within(all_containers[1]) { expect(page).to have_selector('.post-content', exact_text: 'other text 1') }
      within(all_containers[2]) { expect(page).to have_selector('.post-content', exact_text: 'other text 2') }
      within(all_containers[3]) { expect(page).to have_selector('.post-content', exact_text: 'other text 3') }
      within(all_containers[4]) { expect(page).to have_selector('.post-content', exact_text: 'example text 2') }

      # Now test using the "Save Previewed" button
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 4'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 5'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 6'
      end
      accept_alert { click_button "Save Previewed" }
      expect(page).to have_selector('.post-container', count: 6)
      all_containers = page.find_all(".post-container")
      within(all_containers[1]) { expect(page).to have_selector('.post-content', exact_text: 'other text 4') }
      within(all_containers[2]) { expect(page).to have_selector('.post-content', exact_text: 'other text 5') }
      within(all_containers[3]) { expect(page).to have_selector('.post-content', exact_text: 'other text 2') }
      within(all_containers[4]) { expect(page).to have_selector('.post-content', exact_text: 'other text 3') }
      within(all_containers[5]) { expect(page).to have_selector('.post-content', exact_text: 'example text 2') }
      expect(page).to have_no_text("other text 6")

      # Now test discarding
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'text to discard 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'text to discard 2'
        accept_alert { click_button "Discard Replies" }
      end
      expect(page).to have_no_text("text to discard")
    end

    scenario "handles NPC saving errors", :js do
      user = login
      user.update!(default_editor: 'html')

      create(:character, user: user) # User has to have at least one character to be able to create an NPC
      npc = create(:character, npc: true, user: user)
      reply_stub = create(:reply, user: user, character: npc)
      visit reply_path(reply_stub)

      reply = create(:reply, user: user, content: 'example text', editor_mode: 'html')
      create(:reply, user: user, post: reply.post, content: 'example text 2')
      visit reply_path(reply)
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
        page.find('img[title="Choose Character"]').click
        click_button 'NPC'
      end
      page.find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
      new_npc_name = npc.name + "different"
      page.find('.select2-container--open .select2-search__field').set(new_npc_name)
      page.find('li', exact_text: "Create New: #{new_npc_name}").click

      allow(reply_stub).to receive(:post).and_return(reply.post)
      allow(Reply).to receive(:new).and_return(reply_stub)
      allow(npc).to receive_messages(new_record?: true, save: false)
      within('#post-editor') do
        click_button 'Add More Replies'
      end
      expect(page).to have_selector('.flash.error', text: "There was a problem persisting your new NPC.")
    end

    scenario "handles reply saving errors", :js do
      user = login
      user.update!(default_editor: 'html')

      reply_stub = create(:reply, user: user)
      visit reply_path(reply_stub)

      reply = create(:reply, user: user, content: 'example text', editor_mode: 'html')
      create(:reply, user: user, post: reply.post, content: 'example text 2')
      visit reply_path(reply)
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
      end
      allow(Reply).to receive_messages(find_by: reply, new: reply_stub)
      allow(reply).to receive(:dup).and_return(reply_stub)
      allow(reply_stub).to receive_messages(post: reply.post, dup: reply_stub)
      allow(reply_stub).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      within('#post-editor') do
        click_button 'Save All'
      end
      expect(page).to have_selector('.flash.error', text: "Reply could not be updated.")
    end
  end

  scenario "User tries to edit someone else's reply" do
    reply = create(:reply, content: 'example text')

    login
    visit reply_path(reply)
    within(find_reply_on_page(reply)) do
      expect(page).to have_no_link('Edit')
    end

    visit edit_reply_path(reply)
    expect(page).to have_selector('.error', text: 'You do not have permission to modify this reply.')
    expect(page).to have_current_path(post_path(reply.post))
  end

  scenario "Moderator edits a reply" do
    user = create(:user, password: known_test_password)
    reply = create(:reply, user: user, content: 'example text')

    login(create(:mod_user, password: known_test_password), known_test_password)

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      fill_in 'Moderator note', with: 'example edit'
      click_button 'Save'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply updated.')
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'other text')
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end

  scenario "Moderator edits a reply with preview" do
    user = create(:user, password: known_test_password)
    reply = create(:reply, user: user, content: 'example text')

    login(create(:mod_user, password: known_test_password), known_test_password)

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      fill_in 'Moderator note', with: 'example edit'
      click_button 'Preview'
    end

    # verify preview, change again
    expect(page).to have_no_selector('.error')
    expect(page).to have_no_selector('.success')
    expect(page).to have_selector('.content-header', exact_text: reply.post.subject)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      expect(page).to have_selector('.post-content', exact_text: 'other text')
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end

    within('#post-editor') do
      expect(page).to have_field('reply_content', with: 'other text')
      expect(page).to have_field('Moderator note', with: 'example edit')
      fill_in 'reply_content', with: 'third text'
      fill_in 'Moderator note', with: 'another edit'
      click_button 'Save'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply updated.')
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'third text')
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end
end
