RSpec.describe 'Drafts' do
  describe 'create'

  describe "drafts" do
    it "can be created and deleted" do
      thread = create(:post)

      login
      get "/posts/#{thread.id}"
      expect(response).to have_http_status(200)

      # create draft
      expect {
        post "/replies", params: { reply: { post_id: thread.id, content: "Test content" }, button_draft: 'Save Draft' }
      }.to change { ReplyDraft.count }.by(1).and not_change { Reply.count }
      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(thread, page: 'unread', anchor: 'unread'))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Draft saved.")
      end
      follow_redirect!
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Test content")
        expect(response.body).to include("Delete Draft")
      end

      # delete draft
      expect {
        post "/replies", params: { reply: { post_id: thread.id, content: "Test content" }, button_delete_draft: 'Delete Draft' }
      }.to change { ReplyDraft.count }.by(-1).and not_change { Reply.count }
      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(thread, page: 'unread', anchor: 'unread'))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Draft deleted.")
      end
      follow_redirect!
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).not_to include("Test content")
        expect(response.body).not_to include("Delete Draft")
      end

      # try forcing another delete
      expect {
        post "/replies", params: { reply: { post_id: thread.id, content: "Test content" }, button_delete_draft: 'Delete Draft' }
      }.to not_change { ReplyDraft.count }.and not_change { Reply.count }
      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(thread, page: 'unread', anchor: 'unread'))
        expect(flash[:error]).to eq({ message: "Draft could not be deleted", array: nil })
        expect(flash[:success]).to be_nil
      end
    end
  end
end
