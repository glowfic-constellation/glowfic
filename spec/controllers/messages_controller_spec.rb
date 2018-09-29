require "spec_helper"

RSpec.describe MessagesController do
  describe "GET index" do
    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "with views" do
      render_views
      it "assigns correct inbox variables" do
        user = create(:user)
        login_as(user)
        messages = Array.new(4) { create(:message, recipient: user) }
        get :index
        expect(response).to have_http_status(200)
        expect(assigns(:view)).to eq('inbox')
        expect(assigns(:page_title)).to eq('Inbox')
        expect(assigns(:messages)).to match_array(messages)
      end

      it "assigns correct outbox variables" do
        user = create(:user)
        login_as(user)
        messages = Array.new(4) { create(:message, sender: user) }
        get :index, params: { view: 'outbox' }
        expect(response).to have_http_status(200)
        expect(assigns(:view)).to eq('outbox')
        expect(assigns(:page_title)).to eq('Outbox')
        expect(assigns(:messages)).to match_array(messages)
      end
    end

    it "orders messages correctly" do
      skip "TODO: test ordering"
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "handles provided invalid recipient" do
      login
      get :new, params: { recipient_id: -1 }
      expect(response.status).to eq(200)
      expect(assigns(:message).recipient_id).to be_nil
    end

    it "handles provided valid recipient" do
      login
      recipient = create(:user)
      get :new, params: { recipient_id: recipient.id }
      expect(response.status).to eq(200)
      expect(assigns(:message).recipient_id).to eq(recipient.id)
    end

    it "handles provided blocked user" do
      block = create(:block)
      login_as(block.blocking_user)
      get :new, params: { recipient_id: block.blocked_user_id }
      expect(response.status).to eq(200)
      expect(assigns(:message).recipient_id).to be_nil
    end

    it "handles provided blocking user" do
      block = create(:block)
      login_as(block.blocked_user)
      get :new, params: { recipient_id: block.blocking_user_id }
      expect(response.status).to eq(200)
      expect(assigns(:message).recipient_id).to be_nil
    end

    it "hides blocked users" do
      user = create(:user)
      login_as(user)
      create_list(:block, 2, blocked_user: user)
      create_list(:block, 2, blocking_user: user)
      other_users = create_list(:user, 2).sort_by!(&:username).pluck(:username, :id)
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:select_items)).to match_array(Users: other_users)
    end

    context "with views" do
      render_views

      it "succeeds" do
        login
        get :new
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq('Compose Message')
        expect(assigns(:message)).to be_an_instance_of(Message)
        expect(assigns(:message)).to be_a_new_record
        expect(assigns(:javascripts)).to include('messages')
      end

      it "sets succeeds with previous messages" do
        user = create(:user)
        messages = Array.new(7) { create(:message, sender: user) }
        recents = messages[-5..-1].map(&:recipient)
        recents_data = recents.reverse.map{|x| [x.username, x.id] }
        users_data = messages.map(&:recipient).map{|x| [x.username, x.id]}
        users_data.sort_by! {|x| x[0]}
        login_as(user)
        get :new
        expect(response).to have_http_status(200)
        expect(assigns(:select_items)).to eq({'Recently messaged': recents_data, 'Other users': users_data})
      end
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with invalid params" do
      user = create(:user)
      login_as(user)
      messages = Array.new(2) { create(:message, sender: user) }
      recents = messages.map(&:recipient).map{|x| [x.username, x.id]}
      recents_data = recents.reverse
      other_user = create(:user)
      users_data = recents + [[other_user.username, other_user.id]]
      users_data.sort_by! {|x| x[0]}

      post :create, params: { message: {} }
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Your message could not be sent because of the following problems:")
      expect(assigns(:message)).not_to be_valid
      expect(assigns(:page_title)).to eq('Compose Message')
      expect(assigns(:javascripts)).to include('messages')
      expect(assigns(:select_items)).to eq({'Recently messaged': recents_data, 'Other users': users_data})
    end

    it "succeeds with valid recipient" do
      login
      recipient = create(:user)
      post :create, params: { message: {subject: 'test', message: 'testing', recipient_id: recipient.id} }
      expect(response).to redirect_to(messages_url(view: 'inbox'))
      expect(flash[:success]).to eq('Message sent!')
      message = assigns(:message).reload
      expect(message.subject).to eq('test')
      expect(message.message).to eq('testing')
      expect(message.recipient).to eq(recipient)
    end

    it "overrides recipient if you try to forward a message" do
      previous = create(:message)
      other_user = create(:user)
      login_as(previous.recipient)
      post :create, params: { message: {subject: 'Re: ' + previous.subject, message: 'response', recipient_id: other_user.id}, parent_id: previous.id }
      expect(assigns(:message).recipient_id).to eq(previous.sender_id)
    end

    it "fails with invalid parent" do
      login
      post :create, params: { message: {subject: 'Re: Fake', message: 'response'}, parent_id: -1 }
      expect(flash[:error][:array]).to include('Message parent could not be found.')
      expect(assigns(:message).parent).to be_nil
      expect(assigns(:javascripts)).to include('messages')
    end

    it "succeeds with valid parent" do
      previous = create(:message)
      login_as(previous.recipient)
      expect(Message.count).to eq(1)
      post :create, params: { message: {subject: 'Re: ' + previous.subject, message: 'response'}, parent_id: previous.id }
      expect(Message.count).to eq(2)
      expect(response).to redirect_to(messages_path(view: 'inbox'))
      message = assigns(:message).reload
      expect(flash[:success]).to eq('Message sent!')
      expect(message.sender_id).to eq(previous.recipient_id)
      expect(message.recipient_id).to eq(previous.sender_id)
      expect(message.message).to eq('response')
      expect(message.subject).to eq('Re: ' + previous.subject)
      expect(message.parent).to eq(previous)
    end

    it "fails with blocking recipient" do
      block = create(:block)
      login_as(block.blocked_user)
      post :create, params: { message: {subject: 'test', message: 'testing', recipient_id: block.blocking_user } }
      expect(flash[:error]).not_to be_nil
      expect(flash[:error][:message]).to eq("Your message could not be sent because of the following problems:")
      expect(assigns(:message)).not_to be_valid
      expect(assigns(:javascripts)).to include('messages')
    end

    it "fails with blocked recipient" do
      block = create(:block)
      login_as(block.blocking_user)
      post :create, params: { message: {subject: 'test', message: 'testing', recipient_id: block.blocked_user } }
      expect(flash[:error]).not_to be_nil
      expect(flash[:error][:message]).to eq("Your message could not be sent because of the following problems:")
      expect(assigns(:message)).not_to be_valid
      expect(assigns(:javascripts)).to include('messages')
    end

    it "succeeds when replying to own message" do
      previous = create(:message)
      login_as(previous.sender)
      expect(Message.count).to eq(1)
      post :create, params: { message: {subject: 'Re: ' + previous.subject, message: 'response'}, parent_id: previous.id }
      expect(Message.count).to eq(2)
      expect(response).to redirect_to(messages_path(view: 'inbox'))
      expect(flash[:success]).to eq('Message sent!')
      message = assigns(:message).reload
      expect(message.sender_id).to eq(previous.sender_id)
      expect(message.recipient_id).to eq(previous.recipient_id)
      expect(message.parent).to eq(previous)
    end

    context "preview" do
      render_views
      it "sets messages if in a thread" do
        previous = create(:message)
        login_as(previous.sender)
        expect {
          post :create, params: { message: {subject: 'Preview', message: 'example'}, parent_id: previous.id, button_preview: true }
        }.not_to change { Message.count }
        expect(response).to render_template(:preview)
        expect(assigns(:messages)).to eq([previous])
      end

      it "orders messages correctly" do
        skip "TODO: should order a thread by id, check it does"
      end

      it "succeeds" do
        user = create(:user)
        login_as(user)
        messages = Array.new(2) { create(:message, sender: user) }
        recents = messages.map(&:recipient).map{|x| [x.username, x.id]}
        recents_data = recents.reverse
        other_user = create(:user)
        users_data = recents + [[other_user.username, other_user.id]]
        users_data.sort_by! {|x| x[0]}

        expect {
          post :create, params: { message: {subject: 'Preview', message: 'example'}, button_preview: true }
        }.not_to change { Message.count }
        expect(response).to render_template(:preview)
        expect(assigns(:javascripts)).to include('messages')
        expect(assigns(:select_items)).to eq({'Recently messaged': recents_data, 'Other users': users_data})
      end
    end
  end

  describe "GET show" do
    it "requires login" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid message" do
      login
      get :show, params: { id: -1 }
      expect(response).to redirect_to(messages_url(view: 'inbox'))
      expect(flash[:error]).to eq("Message could not be found.")
    end

    it "requires your message" do
      message = create(:message)
      login
      get :show, params: { id: message.id }
      expect(response).to redirect_to(messages_url(view: 'inbox'))
      expect(flash[:error]).to eq("That is not your message!")
    end

    context "with views" do
      render_views
      it "works for sender" do
        message = create(:message)
        login_as(message.sender)
        get :show, params: { id: message.id }
        expect(response).to have_http_status(200)
        expect(assigns(:messages)).to eq([message])
        expect(message.reload.unread?).to eq(true)
      end

      it "works for recipient" do
        message = create(:message)
        login_as(message.recipient)
        get :show, params: { id: message.id }
        expect(response).to have_http_status(200)
        expect(assigns(:messages)).to eq([message])
        expect(message.reload.unread?).not_to eq(true)
      end

      it "works for unread in thread" do
        message = create(:message, unread: true)
        create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: false) # sender
        subsequent = create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: false)
        login_as(message.recipient)
        get :show, params: { id: subsequent.id }
        expect(response).to have_http_status(200)
        expect(message.reload.unread?).not_to eq(true)
      end
    end

    it "does not remark the message read" do
      message = create(:message, unread: false)
      login_as(message.recipient)
      expect_any_instance_of(Message).not_to receive(:update)
      get :show, params: { id: message.id }
    end

    it "does not remark the message read for unread sender in thread" do
      message = create(:message, unread: true)
      sender = create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: true)
      subsequent = create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: false)
      login_as(message.recipient)
      get :show, params: { id: subsequent.id }
      expect(response).to have_http_status(200)
      expect(message.reload.unread?).not_to eq(true)
      expect(sender.reload.unread?).to eq(true)
    end

    it "correctly orders messages" do
      skip "TODO: should check messages in a thread are ordered by id"
    end
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid action" do
      login
      post :mark
      expect(response).to redirect_to(messages_url)
      expect(flash[:error]).to eq("Could not perform unknown action.")
    end

    context "marking read/unread" do
      it "handles invalid message ids" do
        login
        expect_any_instance_of(Message).not_to receive(:update)
        post :mark, params: { marked_ids: ['nope', -1, '0'], commit: "Mark Read / Unread" }
      end

      it "does not work for users without access" do
        message = create(:message)
        login
        expect_any_instance_of(Message).not_to receive(:update)
        post :mark, params: { marked_ids: [message.id.to_s], commit: "Mark Read / Unread" }
      end

      it "does not work for sender" do
        skip "not yet implemented"
      end

      it "works read for recipient" do
        message = create(:message, unread: true)
        login_as(message.recipient)
        post :mark, params: { marked_ids: [message.id.to_s], commit: "Mark Read / Unread" }
        expect(message.reload.unread).not_to eq(true)
      end

      it "works unread for recipient" do
        message = create(:message, unread: false)
        login_as(message.recipient)
        post :mark, params: { marked_ids: [message.id.to_s], commit: "Mark Read / Unread" }
        expect(message.reload.unread).to eq(true)
      end
    end

    context "deleting" do
      it "handles invalid message ids" do
        login
        expect_any_instance_of(Message).not_to receive(:update)
        post :mark, params: { marked_ids: ['nope', -1, '0'], commit: "Delete" }
      end

      it "does not work for users without access" do
        message = create(:message)
        login
        expect_any_instance_of(Message).not_to receive(:update)
        post :mark, params: { marked_ids: [message.id.to_s], commit: "Delete" }
      end

      context "sender" do
        it "works" do
          message = create(:message)
          login_as(message.sender)
          expect(message.visible_outbox).to eq(true)
          post :mark, params: { marked_ids: [message.id.to_s], commit: "Delete" }
          expect(message.reload.visible_outbox).not_to eq(true)
        end
      end

      context "recipient" do
        it "works" do
          message = create(:message)
          login_as(message.recipient)
          expect(message.visible_inbox).to eq(true)
          post :mark, params: { marked_ids: [message.id.to_s], commit: "Delete" }
          expect(message.reload.visible_inbox).not_to eq(true)
        end
      end
    end
  end

  describe "#editor_setup" do
    it "correctly finds and orders users not the current one" do
      login
      user3 = create(:user, username: 'user3')
      user2 = create(:user, username: 'user2')
      user4 = create(:user, username: 'user4')
      user1 = create(:user, username: 'user1')
      controller.send(:editor_setup)
      expect(assigns(:select_items)).to eq({:Users => [[user1.username, user1.id], [user2.username, user2.id], [user3.username, user3.id], [user4.username, user4.id]]})
    end
  end
end
