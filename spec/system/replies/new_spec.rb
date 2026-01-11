RSpec.describe "Creating replies" do
  let(:user) { create(:user, default_editor: 'html') }
  let(:post) { create(:post, subject: 'Sample post') }
  let(:char) { create(:character, name: "Base Character", user: user) }

  context 'logged in' do
    before(:each) { login(user) }

    scenario "User replies to own post" do
      post = create(:post, user: user)

      visit post_path(post)
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_no_selector('.post-expander', text: 'Join Thread')
      expect(page).to have_selector('#post-editor')

      # preview first:
      within('#post-editor') do
        click_button 'Preview'
      end
      expect(page).to have_selector('.flash.success', exact_text: 'Draft saved.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('#post-editor')

      # then save:
      within('#post-editor') do
        click_button 'Post'
      end

      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')

      expect(page).to have_selector('.post-container', count: 2)
      within('.post-reply') do
        expect(page).to have_selector('.post-author', exact_text: user.username)
        expect(page).to have_no_selector('.post-icon')
        expect(page).to have_no_selector('.post-character')
        expect(page).to have_no_selector('.post-screenname')
      end

      # check author list
      visit stats_post_path(post)
      within(row_for('Authors')) do
        expect(page).to have_selector('a', count: 1)
        expect(page).to have_link(exact_text: user.username, href: user_path(user))
      end
    end

    scenario "User replies to open post", :js do
      visit post_path(post)
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('.post-expander', text: 'Join Thread')
      find(".post-expander", text: "+ Join Thread").click

      within('#post-editor') do
        click_button 'Post'
      end

      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')

      expect(page).to have_selector('.post-container', count: 2)
      within('.post-reply') do
        expect(page).to have_selector('.post-author', exact_text: user.username)
        expect(page).to have_no_selector('.post-icon')
        expect(page).to have_no_selector('.post-character')
        expect(page).to have_no_selector('.post-screenname')
      end

      # check author list
      visit stats_post_path(post)
      within(row_for('Authors')) do
        expect(page).to have_selector('a', count: 2)
        expect(page).to have_link(exact_text: post.user.username, href: user_path(post.user))
        expect(page).to have_link(exact_text: user.username, href: user_path(user))
      end
    end

    scenario "User interacts with javascript", :js do
      icon = create(:icon, user: user, keyword: "<strong> icon")
      gallery = create(:gallery, user: user, name: "icons of the <strong>", icons: [icon])
      icon2 = create(:icon, user: user)
      gallery2 = create(:gallery, user: user, icons: [icon2])
      create(:character, user: user, name: "Alice")
      fred = create(:character, user: user, name: "Fred the <strong>!", galleries: [gallery, gallery2])
      create(:alias, character: fred, name: "Fred")
      create(:alias, character: fred, name: "The <strong>!")
      create(:character, user: user, name: "John")

      visit post_path(post)
      expect(page).to have_selector('.post-container', count: 1)
      find(".post-expander", text: "+ Join Thread").click

      within('#post-editor') do
        find('img[title="Choose Character"]').click
        select "Fred the <strong>!", from: "active_character"

        find('img[title="Choose Alias"]').click
        select "The <strong>!", from: "character_alias"

        find_by_id('current-icon-holder').click
        expect(page).to have_text("icons of the <strong>")
        find(:xpath, "//*[contains(@class,'gallery-icon')][contains(text(),'<strong> icon')]//img").click

        click_button "HTML"

        fill_in "reply_content", with: "test reply!"
        click_button "Post"
      end

      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')

      expect(page).to have_selector('.post-container', count: 2)
      within('.post-reply') do
        expect(page).to have_text(user.username)
        expect(page).to have_text("test reply!")
        expect(page).to have_text("The <strong>!")
        expect(find(".post-icon img")[:alt]).to eq("<strong> icon")
      end
    end

    scenario "User creates a reply with a new NPC", :js do
      post.update!(settings: [create(:setting, name: "Settingsverse")])
      char # user must have at least 1 character to be able to pick a character

      visit post_path(post)
      find('.post-expander', text: 'Join Thread').click
      find('img[title="Choose Character"]').click
      click_button 'NPC'
      find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
      find('.select2-container--open .select2-search__field').set('Jade')
      find('li', exact_text: 'Create New: Jade').click
      expect(page).to have_selector('#name', exact_text: 'Jade')
      click_button 'Preview'

      # verify preview, change
      expect(page).to have_text("Draft saved. Your new NPC character has also been persisted!")
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.content-header', exact_text: 'Sample post')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')
      expect(page).to have_selector('#post-editor #name', exact_text: 'Jade')
      click_button 'Post'

      # reply uses NPC
      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-reply', count: 1)

      within('.post-reply') do
        expect(page).to have_text('Jade')
        click_link 'Jade'
      end

      expect(page).to have_text(/Jade\s+\(NPC\)/)
      expect(page).to have_text(/Original post.*Sample post/)
      expect(page).to have_text(/Setting.*Settingsverse/)
    end

    scenario "User creates a reply with an existing NPC", :js do
      char # user must have at least 1 character to be able to pick a character
      npc = create(:character, user: user, name: "Janet", nickname: "Post number 1", npc: true)

      visit post_path(post)
      find('.post-expander', text: 'Join Thread').click
      find('img[title="Choose Character"]').click
      click_button 'NPC'
      find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
      find('li', exact_text: 'Janet | Post number 1').click
      expect(page).to have_selector('#name', exact_text: 'Janet')
      click_button 'Preview'

      # verify preview, change
      expect(page).to have_text("Draft saved.") # (no NPC created)
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.content-header', exact_text: 'Sample post')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')
      expect(page).to have_selector('#post-editor #name', exact_text: 'Janet')
      click_button 'Post'

      # reply uses NPC
      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-reply', count: 1)

      within('.post-reply') do
        expect(page).to have_link('Janet', href: character_path(npc)) # should be the same Janet as before
      end
    end

    scenario "User creates a reply with an alias", :js do
      create(:alias, name: "Alias 1", character: char)
      create(:alias, name: "Alias 2", character: char)

      # select alias in UI
      visit post_path(post)
      find('.post-expander', text: 'Join Thread').click
      find('img[title="Choose Character"]').click
      find('#swap-character-character .select2-selection__rendered').click
      find('li', exact_text: 'Base Character').click
      expect(page).to have_selector('#name', exact_text: 'Base Character')
      find('img[title="Choose Alias"]').click
      find('.select2-selection__rendered', exact_text: "Base Character").click
      find('li', exact_text: 'Alias 2').click
      expect(page).to have_selector('#name', exact_text: 'Alias 2')
      click_button 'Preview'

      # verify preview
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_text("Draft saved.")
      expect(page).to have_selector('.post-reply .post-character', exact_text: 'Alias 2')
      expect(page).to have_selector('#post-editor #name', exact_text: 'Alias 2')
      click_button 'Post'

      # reply uses alias
      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-reply', count: 1)

      within('.post-reply') do
        expect(page).to have_link('Alias 2', href: character_path(char))
      end

      # new editor should have the same alias selected for continuity
      within('#post-editor') do
        expect(page).to have_selector('#name', exact_text: 'Alias 2')
        click_button "HTML"
        fill_in "reply_content", with: "test reply!"
      end
      click_button "Post"

      # and should save this alias correctly
      expect(page).to have_selector('.post-reply', count: 2)
      all(".post-reply").each do |reply|
        within(reply) do
          expect(page).to have_link('Alias 2', href: character_path(char))
        end
      end
    end

    context "using the multi reply editor" do
      scenario "works", :js do
        char
        npc_name = "Jade"
        visit post_path(post)

        # Use "Post Previewed" button
        find('.post-expander', text: 'Join Thread').click
        find('img[title="Choose Character"]').click
        click_button 'Character'
        find_by_id('select2-active_character-container').click
        first("li", text: char.name).click
        click_button "HTML"

        within('#post-editor') do
          fill_in "reply_content", with: "test reply 1"
          click_button "Add More Replies"
        end

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_selector('.post-container', count: 1)
        expect(page).to have_selector('#post-editor')
        expect(page).to have_no_selector('.flash.error')

        within('#post-editor') do
          expect(page).to have_selector('#name', exact_text: char.name)
          find('img[title="Choose Character"]').click
          click_button 'NPC'
        end

        find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
        find('.select2-container--open .select2-search__field').set(npc_name)
        find('li', exact_text: "Create New: #{npc_name}").click
        expect(page).to have_selector('#name', exact_text: npc_name)

        fill_in "reply_content", with: "test reply 2"
        click_button "Add More Replies"

        expect(page).to have_selector('.flash.success', exact_text: 'Your new NPC has been persisted!')
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_selector('.post-container', count: 2)
        expect(page).to have_selector('#post-editor')
        expect(page).to have_selector('#post-editor #name', exact_text: npc_name)

        fill_in "reply_content", with: "test reply 3"
        click_button "Preview Current"

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_selector('.content-header', exact_text: 'Previewing')
        expect(page).to have_selector('.post-container', count: 3)
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_text("test reply 3", count: 2)
        click_button "Add More Replies"

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_no_selector('.content-header', exact_text: 'Previewing')
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.post-container', count: 3)
        expect(page).to have_text("test reply 3", count: 1)
        fill_in "reply_content", with: "test reply 4"
        accept_alert { click_button "Post Previewed" }

        expect(page).to have_selector('.flash.success', exact_text: 'Replies posted.')
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.post-container', count: 4)
        expect(page).to have_text("test reply 1")
        expect(page).to have_text("test reply 2")
        expect(page).to have_text("test reply 3")
        expect(page).to have_no_text("test reply 4")

        # Use "Post All" button
        within('#post-editor') do
          click_button "HTML"
          fill_in "reply_content", with: "test reply 5"
          click_button "Add More Replies"
        end

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.post-container', count: 1)
        expect(page).to have_selector('#post-editor')

        fill_in "reply_content", with: "test reply 6"
        click_button "Add More Replies"

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.post-container', count: 2)
        expect(page).to have_selector('#post-editor')

        fill_in "reply_content", with: "test reply 7"
        click_button "Post All"

        expect(page).to have_selector('.flash.success', exact_text: 'Replies posted.')
        expect(page).to have_no_selector('.flash.error')

        expect(page).to have_selector('.post-container', count: 7)
        expect(page).to have_no_text("test reply 4")
        expect(page).to have_text("test reply 5")
        expect(page).to have_text("test reply 6")
        expect(page).to have_text("test reply 7")

        # Discard replies
        within('#post-editor') do
          click_button "HTML"
          fill_in "reply_content", with: "test reply 8"
          click_button "Add More Replies"
        end

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.post-container', count: 1)
        expect(page).to have_selector('#post-editor')
        fill_in "reply_content", with: "test reply 9"
        click_button "Add More Replies"
        accept_alert { click_button "Discard Replies" }

        expect(page).to have_no_selector('.flash.error')
        expect(page).to have_selector('.flash.success', exact_text: "Replies discarded.")
        expect(page).to have_selector('.post-container', count: 7)
        expect(page).to have_no_text("test reply 8")
        expect(page).to have_no_text("test reply 9")
      end

      scenario "shows unseen and duplicate replies warnings", :js do
        reply = create(:reply, user: user, post: post, content: "reply to dupe")
        visit post_path(post)

        # Will try to add a reply whose content is duplicated
        within('#post-editor') do
          fill_in "reply_content", with: reply.content
          click_button "Add More Replies"
        end

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_no_selector('.flash.error')

        within('#post-editor') do
          fill_in 'reply_content', with: 'new reply 1'
          click_button 'Add More Replies'
        end

        expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
        expect(page).to have_no_selector('.flash.error')

        within('#post-editor') do
          fill_in 'reply_content', with: 'new reply 2'
          click_button 'Post All'
        end

        expect(page).to have_selector('.flash.error',
          text: 'This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional.',)

        accept_alert { click_button "Post Previewed" }
        expect(page).to have_selector('.post-content', exact_text: reply.content, count: 2)
        expect(page).to have_selector('.post-content', exact_text: 'new reply 1', count: 1)
        expect(page).to have_selector('.post-content', exact_text: 'new reply 2', count: 1)

        # Will add more unseen replies after clicking "Add More Replies"
        within('#post-editor') do
          fill_in 'reply_content', with: 'new reply 3'
          click_button "Add More Replies"
        end

        create(:reply, post: post)

        within('#post-editor') do
          fill_in 'reply_content', with: 'new reply 4'
          click_button 'Post All'
        end
        expect(page).to have_selector('.flash.error', text: "There has been 1 new reply since you last viewed this post.")

        accept_alert { click_button "Post Previewed" }
        expect(page).to have_selector('.post-content', exact_text: 'new reply 3', count: 1)
        expect(page).to have_selector('.post-content', exact_text: 'new reply 4', count: 1)
        expect(page).to have_no_selector('.flash.error')
      end

      scenario "Unseen warning does not duplicate", :js do
        create(:reply, post: post, user: user)
        visit post_path(post)

        # create unseen reply after loading page
        create(:reply, post: post, user: post.user)
        expect(post.replies.count).to eq(2)

        within('#post-editor') do
          fill_in 'reply_content', with: 'new reply 3'
          click_button "Add More Replies"
          fill_in 'reply_content', with: 'reply I do not want to duplicate'
          click_button 'Post All'
        end
        expect(page).to have_selector('.flash.error', text: "There has been 1 new reply since you last viewed this post.")

        click_button "Post All"
        expect(post.replies.count).to eq(4)
        expect(page).to have_selector('.post-content', exact_text: 'new reply 3', count: 1)
        expect(page).to have_selector('.post-content', exact_text: 'reply I do not want to duplicate', count: 1)
        expect(page).to have_no_selector('.flash.error')
      end
    end

    scenario "User tries to reply to locked post" do
      post.update!(authors_locked: true)

      visit post_path(post)

      expect(page).to have_selector('.content-header', exact_text: post.subject)
      expect(page).to have_no_text('Join Thread')
      expect(page).to have_no_selector('#post-editor')
    end
  end

  scenario "Logged-out user tries to reply to post" do
    visit post_path(post)

    expect(page).to have_selector('.content-header', exact_text: post.subject)
    expect(page).to have_no_text('Join Thread')
    expect(page).to have_no_selector('#post-editor')
  end
end
