RSpec.describe "Reply editors and post access" do
  let(:user) { create(:user, default_editor: 'html') }

  def find_reply_on_page(reply)
    find('.post-reply') { |x| x.has_selector?('a', id: "reply-#{reply.id}") }
  end

  before(:each) { login(user) }

  context "when replying" do
    scenario "to their own private post with the multi reply editor", :js do
      post = create(:post, user: user, privacy: :private)
      visit post_path(post)

      within('#post-editor') do
        fill_in 'reply_content', with: 'test reply 1'
        click_button 'Add More Replies'
      end
      expect(page).to have_selector('.content-header', exact_text: 'Adding multiple replies')
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        fill_in 'reply_content', with: 'test reply 2'
        click_button 'Post All'
      end

      expect(page).to have_selector('.flash.success', exact_text: 'Replies posted.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 3)
      expect(page).to have_text('test reply 1')
      expect(page).to have_text('test reply 2')
    end

    scenario "to an access-listed post they can see with the multi reply editor", :js do
      post = create(:post, privacy: :access_list)
      PostViewer.create!(post: post, user: user)
      visit post_path(post)
      find('.post-expander', text: 'Join Thread').click

      within('#post-editor') do
        fill_in 'reply_content', with: 'test reply 1'
        click_button 'Add More Replies'
      end
      # the reply left in the editor is not posted
      fill_in 'reply_content', with: 'test reply 2'
      accept_alert { click_button 'Post Previewed' }

      expect(page).to have_selector('.flash.success', exact_text: 'Reply posted.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 2)
      expect(page).to have_text('test reply 1')
      expect(page).to have_no_text('test reply 2')
    end

    scenario "to a post they lose access to while writing", :js do
      post = create(:post, privacy: :access_list)
      PostViewer.create!(post: post, user: user)
      visit post_path(post)
      find('.post-expander', text: 'Join Thread').click
      fill_in 'reply_content', with: 'test reply'

      post.post_viewers.destroy_all
      click_button 'Post'

      # wait for the request to finish before checking it saved nothing
      expect(page).to have_selector('.flash.error', exact_text: 'You do not have permission to view this post.')
      expect(page).to have_current_path(continuities_path)
      expect(Reply.count).to eq(0)
    end

    scenario "to a post that is completed while writing" do
      post = create(:post, user: user)
      visit post_path(post)
      fill_in 'reply_content', with: 'test reply'

      post.update!(status: :complete)
      expect { click_button 'Post' }.not_to change { Reply.count }

      expect(page).to have_selector('.flash.error', exact_text: 'You do not have permission to reply to this post.')
      expect(page).to have_current_path(post_path(post))
    end

    scenario "previewing a reply to a post they lose access to while writing", :js do
      post = create(:post, privacy: :access_list)
      PostViewer.create!(post: post, user: user)
      visit post_path(post)
      find('.post-expander', text: 'Join Thread').click
      fill_in 'reply_content', with: 'test reply'

      post.post_viewers.destroy_all
      click_button 'Preview'

      expect(page).to have_selector('.flash.error', exact_text: 'You do not have permission to view this post.')
      expect(ReplyDraft.count).to eq(0)
    end
  end

  context "when editing" do
    scenario "a reply in a completed post with the multi reply editor", :js do
      post = create(:post, status: :complete)
      reply = create(:reply, post: post, user: user, content: 'example text', editor_mode: 'html')
      visit reply_path(reply)
      within(find_reply_on_page(reply)) { click_link 'Edit' }

      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
        click_button 'Save All'
      end

      expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 3)
      expect(reply.reload.content).to eq('other text 1')
      expect(post.replies.ordered.last.content).to eq('other text 2')
    end

    scenario "a reply in their own private post with the multi reply editor", :js do
      post = create(:post, user: user, privacy: :private)
      reply = create(:reply, post: post, user: user, content: 'example text', editor_mode: 'html')
      visit reply_path(reply)
      within(find_reply_on_page(reply)) { click_link 'Edit' }

      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
        click_button 'Save All'
      end

      expect(page).to have_selector('.flash.success', exact_text: 'Reply updated.')
      expect(page).to have_selector('.post-container', count: 3)
    end

    scenario "a reply in a post they lose access to while writing", :js do
      post = create(:post, privacy: :access_list)
      PostViewer.create!(post: post, user: user)
      reply = create(:reply, post: post, user: user, content: 'example text', editor_mode: 'html')
      visit reply_path(reply)
      within(find_reply_on_page(reply)) { click_link 'Edit' }

      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 1'
        click_button 'Add More Replies'
      end
      within('#post-editor') do
        fill_in 'reply_content', with: 'other text 2'
      end

      post.post_viewers.destroy_all
      click_button 'Save All'

      expect(page).to have_selector('.flash.error', exact_text: 'You do not have permission to modify this reply.')
      expect(Reply.count).to eq(1)
      expect(reply.reload.content).to eq('example text')
    end
  end
end
