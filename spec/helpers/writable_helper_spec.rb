RSpec.describe WritableHelper do
  describe "#unread_warning" do
    let(:post) { create(:post) }

    before(:each) do
      assign(:post, post)
      without_partial_double_verification do
        allow(helper).to receive(:page).and_return(1)
      end
    end

    it "returns unless replies are present" do
      expect(helper.unread_warning).to eq(nil)
    end

    it "returns on the last page" do
      create(:reply, post: post)
      assign(:replies, post.replies.paginate(page: 1))
      expect(helper.unread_warning).to eq(nil)
    end

    it "returns html on earlier pages" do
      create_list(:reply, 26, post: post)
      assign(:replies, post.replies.paginate(page: 1))
      html = 'You are not on the latest page of the thread '
      html += tag.a('(View unread)', href: unread_path(post), class: 'unread-warning') + ' '
      html += tag.a('(New tab)', href: unread_path(post), class: 'unread-warning', target: '_blank')
      expect(helper.unread_warning).to eq(html)
    end
  end
end
