RSpec.describe Api::V1::MessagesController do
  describe "GET index" do
    let(:user) { create(:user) }

    it "requires login", :show_in_doc do
      get :index
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      api_login_as(create(:reader_user))
      get :index
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid box", :show_in_doc do
      api_login_as(user)
      get :index, params: { box: 'trash' }
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'].size).to eq(1)
    end

    it "loads the inbox by default", :show_in_doc do
      api_login_as(user)
      received = create_list(:message, 2, recipient: user)
      create(:message, sender: user) # sent
      create(:message) # other users
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['box']).to eq('inbox')
      expect(response.parsed_body['results'].pluck('id')).to eq(received.reverse.map(&:id))
    end

    it "loads the outbox", :show_in_doc do
      api_login_as(user)
      create(:message, recipient: user) # received
      sent = create_list(:message, 2, sender: user)
      create(:message) # other users
      get :index, params: { box: 'outbox' }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['box']).to eq('outbox')
      expect(response.parsed_body['results'].pluck('id')).to eq(sent.reverse.map(&:id))
    end

    it "returns the expected fields" do
      api_login_as(user)
      message = create(:message, recipient: user, subject: 'Hello', message: 'Message body')
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results']).to eq([
        {
          'id'           => message.id,
          'thread_id'    => message.id,
          'parent_id'    => nil,
          'subject'      => 'Hello',
          'message'      => 'Message body',
          'created_at'   => message.created_at.utc.as_json,
          'site_message' => false,
          'sender'       => { 'id' => message.sender_id, 'username' => message.sender.username },
          'recipient'    => { 'id' => user.id, 'username' => user.username },
          'unread'       => true,
          'thread'       => {
            'id'            => message.id,
            'subject'       => 'Hello',
            'created_at'    => message.created_at.utc.as_json,
            'message_count' => 1,
            'unread'        => true,
          },
        },
      ])
    end

    it "does not show read state to the sender" do
      api_login_as(user)
      create(:message, sender: user)
      get :index, params: { box: 'outbox' }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'][0]).not_to have_key('unread')
      expect(response.parsed_body['results'][0]['thread']['unread']).to be(false)
    end

    it "returns one entry per thread with the newest message in the box" do
      api_login_as(user)
      other = create(:user)
      first = create(:message, sender: other, recipient: user, subject: 'Thread subject', unread: false)
      create(:message, sender: user, recipient: other, thread_id: first.id, parent: first, subject: '')
      newest = create(:message, sender: other, recipient: user, thread_id: first.id, parent: first, subject: '')
      create(:message, sender: user, recipient: other, thread_id: first.id, parent: first, subject: '')
      single = create(:message, recipient: user)

      get :index
      expect(response).to have_http_status(200)
      results = response.parsed_body['results']
      expect(results.pluck('id')).to eq([single.id, newest.id])
      expect(results[1]['thread_id']).to eq(first.id)
      expect(results[1]['sender']['id']).to eq(other.id)
      expect(results[1]['unread']).to be(true)
      expect(results[1]['thread']).to include(
        'id'            => first.id,
        'subject'       => 'Thread subject',
        'created_at'    => first.created_at.utc.as_json,
        'message_count' => 4,
        'unread'        => true,
      )
      expect(results[0]['thread']['message_count']).to eq(1)
    end

    it "marks a thread unread only for the user's own unread messages" do
      api_login_as(user)
      other = create(:user)
      first = create(:message, sender: other, recipient: user, unread: false)
      create(:message, sender: user, recipient: other, thread_id: first.id, parent: first, unread: true)
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'][0]['thread']['unread']).to be(false)
    end

    it "includes site messages" do
      api_login_as(user)
      message = create(:message, sender_id: 0, recipient: user)
      get :index
      expect(response).to have_http_status(200)
      result = response.parsed_body['results'][0]
      expect(result['id']).to eq(message.id)
      expect(result['site_message']).to be(true)
      expect(result['sender']).to be_nil
    end

    it "excludes messages with deleted users" do
      api_login_as(user)
      received = create(:message, recipient: user)
      create(:message, recipient: user).sender.archive
      sent = create(:message, sender: user)
      create(:message, sender: user).recipient.archive

      get :index
      expect(response.parsed_body['results'].pluck('id')).to eq([received.id])
      get :index, params: { box: 'outbox' }
      expect(response.parsed_body['results'].pluck('id')).to eq([sent.id])
    end

    it "excludes messages deleted from the box" do
      api_login_as(user)
      received = create(:message, recipient: user)
      create(:message, recipient: user, visible_inbox: false)
      sent = create(:message, sender: user)
      create(:message, sender: user, visible_outbox: false)

      get :index
      expect(response.parsed_body['results'].pluck('id')).to eq([received.id])
      get :index, params: { box: 'outbox' }
      expect(response.parsed_body['results'].pluck('id')).to eq([sent.id])
    end

    it "excludes messages with blocked users" do
      api_login_as(user)
      other = create(:user)
      create(:message, sender: other, recipient: user)
      create(:message, sender: user, recipient: other)
      create(:block, blocking_user: user, blocked_user: other)

      get :index
      expect(response.parsed_body['results']).to be_empty
      get :index, params: { box: 'outbox' }
      expect(response.parsed_body['results']).to be_empty
    end

    it "excludes messages that were hidden because the recipient blocked the sender" do
      api_login_as(user)
      other = create(:user)
      create(:block, blocking_user: user, blocked_user: other, block_interactions: true)
      blocked = create(:message, sender: other, recipient: user)
      expect(blocked.reload.visible_inbox).to be(false)
      Block.find_by(blocking_user: user).destroy!

      get :index
      expect(response.parsed_body['results']).to be_empty
    end

    it "paginates" do
      api_login_as(user)
      create_list(:message, 5, recipient: user)
      get :index, params: { per_page: 2, page: 3 }
      expect(response).to have_http_status(200)
      expect(response.headers['Per-Page'].to_i).to eq(2)
      expect(response.headers['Page'].to_i).to eq(3)
      expect(response.headers['Total'].to_i).to eq(5)
      expect(response.headers['Link']).not_to be_nil
      expect(response.parsed_body['results'].size).to eq(1)
    end

    it "does not mark messages read" do
      api_login_as(user)
      message = create(:message, recipient: user)
      get :index
      expect(response).to have_http_status(200)
      expect(message.reload.unread).to be(true)
    end
  end

  describe "GET show" do
    let(:message) { create(:message) }

    it "requires login", :show_in_doc do
      get :show, params: { id: message.id }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      api_login_as(create(:reader_user))
      get :show, params: { id: message.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid message", :show_in_doc do
      api_login
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'][0]['message']).to eq("Message could not be found.")
    end

    it "requires your message", :show_in_doc do
      api_login
      get :show, params: { id: message.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "requires extant sender" do
      api_login_as(message.recipient)
      message.sender.archive
      get :show, params: { id: message.id }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'][0]['message']).to eq("Message could not be found.")
    end

    it "requires extant recipient" do
      api_login_as(message.sender)
      message.recipient.archive
      get :show, params: { id: message.id }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'][0]['message']).to eq("Message could not be found.")
    end

    it "works for recipient without marking the message read", :show_in_doc do
      api_login_as(message.recipient)
      get :show, params: { id: message.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['message']['id']).to eq(message.id)
      expect(response.parsed_body['message']['unread']).to be(true)
      expect(response.parsed_body['box']).to eq('inbox')
      expect(response.parsed_body['thread']['messages'].pluck('id')).to eq([message.id])
      expect(message.reload.unread).to be(true)
      expect(message.read_at).to be_nil
    end

    it "works for sender without showing read state" do
      api_login_as(message.sender)
      get :show, params: { id: message.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['message']['id']).to eq(message.id)
      expect(response.parsed_body['message']).not_to have_key('unread')
      expect(response.parsed_body['box']).to eq('outbox')
      expect(message.reload.unread).to be(true)
    end

    it "works for site messages" do
      site_message = create(:message, sender_id: 0)
      api_login_as(site_message.recipient)
      get :show, params: { id: site_message.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['message']['site_message']).to be(true)
      expect(response.parsed_body['message']['sender']).to be_nil
    end

    it "returns the whole thread in order" do
      sender = message.sender
      recipient = message.recipient
      reply = create(:message, sender: recipient, recipient: sender, thread_id: message.id, parent: message, subject: '')
      last = create(:message, sender: sender, recipient: recipient, thread_id: message.id, parent: reply, subject: '')
      api_login_as(recipient)

      get :show, params: { id: reply.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['message']['id']).to eq(reply.id)
      expect(response.parsed_body['message']).not_to have_key('unread')
      expect(response.parsed_body['box']).to eq('outbox')
      thread = response.parsed_body['thread']
      expect(thread['id']).to eq(message.id)
      expect(thread['subject']).to eq(message.subject)
      expect(thread['messages'].pluck('id')).to eq([message.id, reply.id, last.id])
      expect(thread['messages'].pluck('unread')).to eq([true, nil, true])
      expect(thread['messages'][1]).not_to have_key('unread')
      expect(thread['messages'][2]['parent_id']).to eq(reply.id)
      expect(message.reload.unread).to be(true)
      expect(last.reload.unread).to be(true)
    end
  end
end
