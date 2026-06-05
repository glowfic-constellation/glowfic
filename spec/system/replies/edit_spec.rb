TIME_FORMAT = '%b %d, %Y %-l:%M %p'

RSpec.describe "Editing replies" do
  let(:user) { create(:user, default_editor: 'html') }
  let(:reply) { create(:reply, user: user, content: 'example text', editor_mode: 'html') }

  def find_reply_on_page(reply)
    find('.post-reply') { |x| x.has_selector?('a', id: "reply-#{reply.id}") }
  end

  scenario "Logged-out user tries to edit a reply" do
    visit reply_path(reply)
    within(find_reply_on_page(reply)) do
      expect(page).to have_no_link('Edit')
    end

    visit edit_reply_path(reply)
    expect(page).to have_selector('.flash.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
    expect(page).to have_no_selector('#post-editor')
  end

  scenario "User edits a reply" do
    login(user)

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      click_button 'submit_button'
    end

    expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
    expect(page).to have_no_selector('.flash.error')

    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'other text')
    end
  end

  scenario "User edits a reply with preview" do
    login(user)

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      click_button 'Preview'
    end

    # verify preview, change again
    expect(page).to have_selector('.content-header', exact_text: reply.post.subject)
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_no_selector('.flash.success')

    expect(page).to have_selector('.post-container .post-content', exact_text: 'other text')

    within('#post-editor') do
      expect(page).to have_field('reply_content', with: 'other text')
      fill_in 'reply_content', with: 'third text'
      click_button 'submit_button'
    end

    expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
    expect(page).to have_no_selector('.flash.error')

    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'third text')
    end
  end

  context "using the multi reply editor" do
    scenario "works", :js do
      login(user)

      reply = Reply.with_auditing do
        Timecop.freeze(2.weeks.ago) do
          reply = create(:reply, user: user, content: 'example text', editor_mode: 'html')
          create(:reply, user: user, post: reply.post, content: 'example text 2')
          reply
        end
      end

      tagged_at = reply.post.tagged_at

      visit reply_path(reply)
      expect(page).to have_selector('.post-container', count: 3)
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end

      # add two extra replies
      expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
      expect(page).to have_no_selector('.post-container')
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end

      expect(page).to have_selector('.content-header', exact_text: 'Editing reply and adding more')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
        click_button 'Add More Replies'
      end

      expect(page).to have_selector('.content-header', exact_text: 'Editing reply and adding more')
      expect(page).to have_selector('.post-container', count: 2)
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 3'
        click_button 'Save All'
      end

      # All replies should be there in the right order
      expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 5)
      all_containers = find_all(".post-container")

      within(all_containers[1]) do
        expect(page).to have_selector('.post-content', exact_text: 'other text 1')
        expect(page).to have_selector('.post-footer', text: "Posted #{reply.created_at.strftime(TIME_FORMAT)} | Updated")
      end

      within(all_containers[2]) do
        expect(page).to have_selector('.post-content', exact_text: 'other text 2')
        expect(page).to have_selector('.post-footer', text: "Posted #{reply.created_at.strftime(TIME_FORMAT)} | Updated")
      end

      within(all_containers[3]) do
        expect(page).to have_selector('.post-content', exact_text: 'other text 3')
        expect(page).to have_selector('.post-footer', text: "Posted #{reply.created_at.strftime(TIME_FORMAT)} | Updated")
      end

      within(all_containers[4]) { expect(page).to have_selector('.post-content', exact_text: 'example text 2') }

      expect(reply.post.reload.tagged_at).to be_the_same_time_as(tagged_at)

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
      all_containers = all(".post-container")
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

    scenario "does not show unseen or duplicate replies warnings", :js do
      login(user)
      reply
      create(:reply, user: user, post: reply.post, content: 'example text 2')

      visit reply_path(reply)
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end

      # Create extra replies "on a different tab"
      create(:reply, post: reply.post) # Another user's reply
      create(:reply, user: user, post: reply.post, content: 'other text 1') # reply by the same user with the same content as first multi-reply
      create(:reply, user: user, post: reply.post, content: 'other text 3') # reply by the same user with the same content as last multi-reply

      # add extra replies
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 3'
        click_button 'Save All'
      end

      # Reply should be split without showing the "unseen replies" or "duplicate reply" warnings
      expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
      expect(page).to have_no_selector('.flash.error')

      expect(page).to have_selector('.post-container', count: 8)
      expect(page).to have_selector('.post-content', exact_text: 'other text 1', count: 2)
      expect(page).to have_selector('.post-content', exact_text: 'other text 3', count: 2)
    end

    scenario "interacts correctly with the quick switcher", :js do
      login(user)

      # Create characters and aliases
      char1 = create(:character, user: user, name: "char1")
      char1_alias = create(:alias, character: char1, name: "char1_alias")
      char2 = create(:character, user: user, name: "char2")
      char2_alias = create(:alias, character: char2, name: "char2_alias")
      char3 = create(:character, user: user, name: "char3")
      char3_alias = create(:alias, character: char3, name: "char3_alias")
      char4 = create(:character, user: user, name: "char4")
      char4_alias = create(:alias, character: char4, name: "char4_alias")

      # Create replies with those characters and aliases
      post = create(:post)
      reply = create(:reply, post: post, user: user)
      create(:reply, post: post, user: user, character: char1)
      create(:reply, post: post, user: user, character: char2, character_alias: char2_alias)
      create(:reply, post: post, user: user, character: char3)
      create(:reply, post: post, user: user, character: char3, character_alias: char3_alias)

      visit reply_path(reply)
      within(find_reply_on_page(reply)) do
        click_link 'Edit'
      end

      # Check that the quick switcher has the characters in the right orders
      switcher_chars = within('.post-char-access') do
        switcher_chars = all('.char-access-icon')
        expect(switcher_chars.size).to eq(4)

        expected_ids = ["", char3.id.to_s, char2.id.to_s, char1.id.to_s]
        actual_ids = switcher_chars.pluck(:'data-character-id')

        expect(actual_ids).to eq(expected_ids)

        switcher_chars
      end

      # Check that all aliases are selected correctly
      switcher_chars[1].click
      expect(page).to have_selector('.post-character #name', exact_text: char3_alias.name)
      switcher_chars[2].click
      expect(page).to have_selector('.post-character #name', exact_text: char2_alias.name)
      switcher_chars[3].click
      within('.post-character') do
        expect(page).to have_selector('#name', exact_text: char1.name)

        find_by_id('swap-alias').click
        find_by_id('select2-character_alias-container').click
      end

      # Change the character's alias and submit to multi-reply editor
      find('li', exact_text: char1_alias.name).click
      click_button "Add More Replies"

      within('#post-editor') do
        # Check that the switcher has the correct characters in the right order
        switcher_chars = within('.post-char-access') do
          switcher_chars = all('.char-access-icon')
          expect(switcher_chars.size).to eq(4)

          expected_ids = ["", char1.id.to_s, char3.id.to_s, char2.id.to_s]
          actual_ids = switcher_chars.pluck(:'data-character-id')

          expect(actual_ids).to eq(expected_ids)

          switcher_chars
        end

        # Check that alias is selected correctly
        expect(page).to have_selector('.post-character #name', exact_text: char1_alias.name)
        switcher_chars[2].click
        expect(page).to have_selector('.post-character #name', exact_text: char3_alias.name)
        switcher_chars[1].click
        expect(page).to have_selector('.post-character #name', exact_text: char1_alias.name)

        # Include a new character
        within('.post-author') do
          find_by_id('swap-character').click
          find_by_id('select2-active_character-container').click
        end
      end

      find('li', exact_text: char4.name).click
      click_button "HTML" # Just to force the editor to update
      click_button "Add More Replies"

      within('#post-editor') do
        # Check that the switcher has the correct characters in the right order
        switcher_chars = within('.post-char-access') do
          switcher_chars = all('.char-access-icon')
          expect(switcher_chars.size).to eq(5)

          expected_ids = ["", char4.id.to_s, char1.id.to_s, char3.id.to_s, char2.id.to_s]
          actual_ids = switcher_chars.pluck(:'data-character-id')

          expect(actual_ids).to eq(expected_ids)

          switcher_chars
        end

        # Check that aliases are selected correctly
        expect(page).to have_selector('.post-character #name', exact_text: char4.name)
        switcher_chars[2].click
        expect(page).to have_selector('.post-character #name', exact_text: char1_alias.name)
        switcher_chars[1].click
        within('.post-character') do
          expect(page).to have_selector('#name', exact_text: char4.name)

          find_by_id('swap-alias').click
          find_by_id('select2-character_alias-container').click
        end
      end

      # Change the character's alias and submit to multi-reply editor
      find('li', exact_text: char4_alias.name).click
      click_button "Add More Replies"
      expect(page).to have_selector('#post-editor .post-character #name', exact_text: char4_alias.name)
    end

    scenario "handles NPC saving errors", :js do
      login(user)

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
        find('img[title="Choose Character"]').click
        click_button 'NPC'
      end

      find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
      new_npc_name = npc.name + "different"
      find('.select2-container--open .select2-search__field').set(new_npc_name)
      find('li', exact_text: "Create New: #{new_npc_name}").click

      allow(reply_stub).to receive(:post).and_return(reply.post)
      allow(Reply).to receive(:new).and_return(reply_stub)
      allow(npc).to receive_messages(new_record?: true, save: false)

      within('#post-editor') do
        click_button 'Add More Replies'
      end

      expect(page).to have_selector('.flash.error', text: "There was a problem persisting your new NPC.")
    end

    scenario "handles reply saving errors", :js do
      login(user)

      reply_stub = create(:reply, user: user)
      visit reply_path(reply_stub)

      reply
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
    login
    visit reply_path(reply)
    within(find_reply_on_page(reply)) do
      expect(page).to have_no_link('Edit')
    end

    visit edit_reply_path(reply)
    expect(page).to have_selector('.flash.error', text: 'You do not have permission to modify this reply.')
    expect(page).to have_current_path(post_path(reply.post))
  end

  scenario "Moderator edits a reply" do
    login(create(:mod_user))

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      fill_in 'Moderator note', with: 'example edit'
      click_button 'Save'
    end

    expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.post-container', count: 2)

    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'other text')
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end

  scenario "Moderator edits a reply with preview" do
    login(create(:mod_user))

    visit reply_path(reply)
    expect(page).to have_selector('.post-container', count: 2)
    within(find_reply_on_page(reply)) do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_selector('.content-header', exact_text: 'Edit reply')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      fill_in 'reply_content', with: 'other text'
      fill_in 'Moderator note', with: 'example edit'
      click_button 'Preview'
    end

    # verify preview, change again
    expect(page).to have_selector('.content-header', exact_text: reply.post.subject)
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_no_selector('.flash.success')

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

    expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.post-container', count: 2)

    within(find_reply_on_page(reply)) do
      expect(page).to have_selector('.post-content', exact_text: 'third text')
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end
end
