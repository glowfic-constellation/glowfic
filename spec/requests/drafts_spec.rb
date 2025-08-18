RSpec.describe 'Drafts' do
  let(:user) { create(:user) }
  let(:rpost) { create(:post, user: user) }

  before(:each) { login(user) }

  describe 'create' do
    it 'works' do
      get "/posts/#{rpost.id}"
      expect(response).to have_http_status(200)

      expect {
        post "/drafts", params: { reply: { post_id: rpost.id, content: "Test content" } }
      }.to change { ReplyDraft.count }.by(1).and not_change { Reply.count }

      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(rpost, page: 'unread', anchor: 'unread'))
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
    end
  end

  describe 'destroy' do
    it 'requires a draft' do
      get "/posts/#{rpost.id}"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).not_to include("Delete Draft")
      end

      expect {
        delete "/drafts/0", params: { reply: { post_id: rpost.id, content: "Test content" } }
      }.to not_change { ReplyDraft.count }.and not_change { Reply.count }

      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(rpost, page: 'unread', anchor: 'unread'))
        expect(flash[:error]).to eq({ message: "Draft could not be deleted", array: nil })
        expect(flash[:success]).to be_nil
      end
    end

    it 'works' do
      draft = create(:reply_draft, user: user, post: rpost, content: 'Test content')

      get "/posts/#{rpost.id}"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include("Delete Draft")
      end

      expect {
        delete "/drafts/#{draft.id}", params: { reply: { post_id: rpost.id, content: "Test content" } }
      }.to change { ReplyDraft.count }.by(-1).and not_change { Reply.count }

      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(rpost, page: 'unread', anchor: 'unread'))
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
    end
  end
end
