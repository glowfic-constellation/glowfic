require "spec_helper"

RSpec.describe MessagesController do
  describe "GET index" do
    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

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
      get :index, view: 'outbox'
      expect(response).to have_http_status(200)
      expect(assigns(:view)).to eq('outbox')
      expect(assigns(:page_title)).to eq('Outbox')
      expect(assigns(:messages)).to match_array(messages)
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
      get :new, recipient_id: -1
      expect(response.status).to eq(200)
      expect(assigns(:message).recipient_id).to be_nil
    end

    it "handles provided valid recipient" do
      login
      recipient = create(:user)
      get :new, recipient_id: recipient.id
      expect(response.status).to eq(200)
      expect(assigns(:message).recipient_id).to eq(recipient.id)
    end

    it "succeeds" do
      login
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq('Compose Message')
      expect(assigns(:message)).to be_an_instance_of(Message)
      expect(assigns(:message)).to be_a_new_record
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with invalid params" do
      login
      post :create, message: {}
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Your message could not be sent because of the following problems:")
      expect(assigns(:message)).not_to be_valid
      expect(assigns(:page_title)).to eq('Compose Message')
    end

    it "succeeds with valid recipient" do
      login
      recipient = create(:user)
      post :create, message: {subject: 'test', message: 'testing', recipient_id: recipient.id}
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
      post :create, message: {subject: 'Re: ' + previous.subject, message: 'response', recipient_id: other_user.id}, parent_id: previous.id
      expect(assigns(:message).recipient_id).to eq(previous.sender_id)
    end

    it "fails with invalid parent" do
      login
      post :create, message: {subject: 'Re: Fake', message: 'response'}, parent_id: -1
      expect(flash[:error][:array]).to include('Message parent could not be found.')
      expect(assigns(:message).parent).to be_nil
    end

    it "succeeds with valid parent" do
      previous = create(:message)
      login_as(previous.recipient)
      expect(Message.count).to eq(1)
      post :create, message: {subject: 'Re: ' + previous.subject, message: 'response'}, parent_id: previous.id
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

    it "succeeds when replying to own message" do
      previous = create(:message)
      login_as(previous.sender)
      expect(Message.count).to eq(1)
      post :create, message: {subject: 'Re: ' + previous.subject, message: 'response'}, parent_id: previous.id
      expect(Message.count).to eq(2)
      expect(response).to redirect_to(messages_path(view: 'inbox'))
      expect(flash[:success]).to eq('Message sent!')
      message = assigns(:message).reload
      expect(message.sender_id).to eq(previous.sender_id)
      expect(message.recipient_id).to eq(previous.recipient_id)
      expect(message.parent).to eq(previous)
    end

    context "preview" do
      it "sets messages if in a thread" do
        previous = create(:message)
        login_as(previous.sender)
        post :create, message: {subject: 'Preview', message: 'example'}, parent_id: previous.id, button_preview: true
        expect(Message.count).to eq(1)
        expect(response).to render_template(:preview)
        expect(assigns(:messages)).to eq([previous])
      end

      it "succeeds" do
        login
        post :create, message: {subject: 'Preview', message: 'example'}, button_preview: true
        expect(Message.count).to eq(0)
        expect(response).to render_template(:preview)
        expect(assigns(:javascripts)).to include('messages')
      end
    end
  end

  describe "GET show" do
    it "requires login" do
      get :show, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid message" do
      login
      get :show, id: -1
      expect(response).to redirect_to(messages_url(view: 'inbox'))
      expect(flash[:error]).to eq("Message could not be found.")
    end

    it "requires your message" do
      message = create(:message)
      login
      get :show, id: message.id
      expect(response).to redirect_to(messages_url(view: 'inbox'))
      expect(flash[:error]).to eq("That is not your message!")
    end

    it "works for sender" do
      message = create(:message)
      login_as(message.sender)
      get :show, id: message.id
      expect(response).to have_http_status(200)
      expect(assigns(:messages)).to eq([message])
      expect(message.reload.unread?).to be_true
    end

    it "works for recipient" do
      message = create(:message)
      login_as(message.recipient)
      get :show, id: message.id
      expect(response).to have_http_status(200)
      expect(assigns(:messages)).to eq([message])
      expect(message.reload.unread?).not_to be_true
    end

    it "works for unread in thread" do
      message = create(:message, unread: true)
      create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: false) # sender
      subsequent = create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: false)
      login_as(message.recipient)
      get :show, id: subsequent.id
      expect(response).to have_http_status(200)
      expect(message.reload.unread?).not_to be_true
    end

    it "does not remark the message read" do
      message = create(:message, unread: false)
      login_as(message.recipient)
      expect_any_instance_of(Message).not_to receive(:update_attributes)
      get :show, id: message.id
    end

    it "does not remark the message read for unread sender in thread" do
      message = create(:message, unread: true)
      sender = create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: true)
      subsequent = create(:message, sender: message.recipient, recipient: message.sender, parent: message, thread_id: message.id, unread: false)
      login_as(message.recipient)
      get :show, id: subsequent.id
      expect(response).to have_http_status(200)
      expect(message.reload.unread?).not_to be_true
      expect(sender.reload.unread?).to be_true
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
        expect_any_instance_of(Message).not_to receive(:update_attributes)
        post :mark, marked_ids: ['nope', -1, '0'], commit: "Mark Read / Unread"
      end

      it "does not work for users without access" do
        message = create(:message)
        login
        expect_any_instance_of(Message).not_to receive(:update_attributes)
        post :mark, marked_ids: [message.id.to_s], commit: "Mark Read / Unread"
      end

      it "does not work for sender" do
        skip "not yet implemented"
      end

      it "works read for recipient" do
        message = create(:message, unread: true)
        login_as(message.recipient)
        post :mark, marked_ids: [message.id.to_s], commit: "Mark Read / Unread"
        expect(message.reload.unread).not_to be_true
      end

      it "works unread for recipient" do
        message = create(:message, unread: false)
        login_as(message.recipient)
        post :mark, marked_ids: [message.id.to_s], commit: "Mark Read / Unread"
        expect(message.reload.unread).to be_true
      end
    end

    context "deleting" do
      it "handles invalid message ids" do
        login
        expect_any_instance_of(Message).not_to receive(:update_attributes)
        post :mark, marked_ids: ['nope', -1, '0'], commit: "Delete"
      end

      it "does not work for users without access" do
        message = create(:message)
        login
        expect_any_instance_of(Message).not_to receive(:update_attributes)
        post :mark, marked_ids: [message.id.to_s], commit: "Delete"
      end

      context "sender" do
        it "works" do
          message = create(:message)
          login_as(message.sender)
          expect(message.visible_outbox).to be_true
          post :mark, marked_ids: [message.id.to_s], commit: "Delete"
          expect(message.reload.visible_outbox).not_to be_true
        end
      end

      context "recipient" do
        it "works" do
          message = create(:message)
          login_as(message.recipient)
          expect(message.visible_inbox).to be_true
          post :mark, marked_ids: [message.id.to_s], commit: "Delete"
          expect(message.reload.visible_inbox).not_to be_true
        end
      end
    end
  end
end
