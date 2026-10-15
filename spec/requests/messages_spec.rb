RSpec.describe "Message" do
  describe "index" do
    def create_thread(sender:, recipient:)
      first = create(:message, sender: sender, recipient: recipient)
      create(:message, sender: sender, recipient: recipient, thread_id: first.id)
      first
    end

    it "shows thread counts and start times" do
      user = login
      first = create_thread(sender: create(:user), recipient: user)
      create(:message, sender: first.sender, recipient: user, thread_id: first.id)
      single = create(:message, recipient: user)
      get "/messages"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include("(3)")
        expect(response.body).not_to include("(1)")
        expect(response.body).to include(first.created_at.utc.iso8601)
        expect(response.body).to include(single.created_at.utc.iso8601)
      end
    end

    it "does not run a query per thread in the inbox" do
      user = login
      create_thread(sender: create(:user), recipient: user)
      expect_constant_queries("/messages") do
        2.times { create_thread(sender: create(:user), recipient: user) }
      end
    end

    it "does not run a query per thread in the outbox" do
      user = login
      create_thread(sender: user, recipient: create(:user))
      expect_constant_queries("/messages?view=outbox") do
        2.times { create_thread(sender: user, recipient: create(:user)) }
      end
    end
  end
end
