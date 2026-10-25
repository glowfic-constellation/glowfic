RSpec.describe "Reply" do
  describe "search" do
    it "works" do
      create(:reply, content: "Sample reply")
      create(:reply, content: "Other reply")

      get "/replies/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Replies")
      end

      get "/replies/search?subj_content=Sample&commit=Search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Replies")
        expect(response.body).to include("<b>Sample</b> reply")
        expect(response.body).not_to include("Other")
      end
    end

    it "works with invalid post" do
      private_post = create(:post, privacy: :private)

      get "/replies/search?post_id=#{private_post.id}&commit=Search"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("You do not have permission to view this post.")
      end
    end
  end

  describe "create" do
    let(:user) { create(:user) }
    let(:coauthor) { create(:user) }
    let(:rpost) { create(:post, user: coauthor, unjoined_authors: [user]) }
    let(:body) { response.parsed_body }

    before(:each) do
      create(:reply, user: user, post: rpost)
      rpost.mark_read(user)
      login(user)
    end

    context "preview" do
      it "works" do
        expect {
          post "/replies", params: { reply: { post_id: rpost.id, content: "Test content" }, button_preview: 'Preview' }
        }.to change { ReplyDraft.count }.by(1).and not_change { Reply.count }

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:preview)
          expect(response).to render_template('replies/_single')
          expect(response).to render_template('replies/_write')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to eq("Draft saved.")

          expect(body.at_css('.content-header').text).to eq(rpost.subject)
          expect(body.at_css('.post-content').text).to eq("Test content")
        end
      end

      it "works with an unseen reply" do
        reply = create(:reply, user: coauthor, post: rpost)

        expect {
          post "/replies", params: { reply: { post_id: rpost.id, content: "Test content" } }
        }.to change { ReplyDraft.count }.by(1).and not_change { Reply.count }

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:preview)
          expect(response).to render_template('replies/_single')
          expect(response).to render_template('replies/_write')

          expect(flash[:error]).to eq('There has been 1 new reply since you last viewed this post.')
          expect(flash[:success]).to eq("Draft saved.")

          expect(body.css('.content-header')[0].text.strip).to eq("Unseen Replies\nUnread »")
          expect(body.css('.post-content')[0].text).to eq(reply.content)
          expect(body.css('.content-header')[1].text).to eq(rpost.subject)
          expect(body.css('.post-content')[1].text).to eq('Test content')
        end
      end

      it "works with many unseen replies" do
        replies = create_list(:reply, 12, user: coauthor, post: rpost)

        expect {
          post "/replies", params: { reply: { post_id: rpost.id, content: "Test content" } }
        }.to change { ReplyDraft.count }.by(1).and not_change { Reply.count }

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:preview)
          expect(response).to render_template('replies/_single')
          expect(response).to render_template('replies/_write')

          expect(flash[:error]).to eq('There have been 12 new replies since you last viewed this post.')
          expect(flash[:success]).to eq("Draft saved.")

          headers = body.css('.content-header')
          contents = body.css('.post-content')

          expect(headers.size).to eq(2)
          expect(contents.size).to eq(11)

          replies[0..9].each_with_index do |reply, i|
            expect(contents[i].text).to eq(reply.content)
          end

          expect(headers[0].text.strip).to eq("Unseen Replies\nUnread »")
          expect(body.at_css('.post-ender').text).to eq('... and 2 more ...')
          expect(headers[1].text).to eq(rpost.subject)
          expect(contents[10].text).to eq('Test content')
        end
      end

      it "works with a post description" do
        rpost.update!(description: 'sample description')

        expect {
          post "/replies", params: { reply: { post_id: rpost.id, content: "Test content" }, button_preview: 'Preview' }
        }.to change { ReplyDraft.count }.by(1).and not_change { Reply.count }

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:preview)
          expect(response).to render_template('replies/_single')
          expect(response).to render_template('replies/_write')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to eq("Draft saved.")

          expect(body.at_css('.content-header').text).to eq(rpost.subject)
          expect(body.at_css('.post-subheader').text).to eq(rpost.description)
          expect(body.at_css('.post-content').text).to eq("Test content")
        end
      end
    end
  end
end
