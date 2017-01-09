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
      messages = 4.times.collect do create(:message, recipient: user) end
      get :index
      expect(response).to have_http_status(200)
      expect(assigns(:view)).to eq('inbox')
      expect(assigns(:page_title)).to eq('Inbox')
      expect(assigns(:messages)).to match_array(messages)
    end

    it "assigns correct outbox variables" do
      user = create(:user)
      login_as(user)
      messages = 4.times.collect do create(:message, sender: user) end
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

    it "handles invalid parent" do
      login
      get :new, reply_id: -1
      expect(flash[:error]).to eq('Message parent could not be found.')
      expect(assigns(:message).parent_id).to be_nil
      expect(assigns(:message).subject).to be_blank
    end

    it "handles provided parent" do
      previous = create(:message)
      login_as(previous.sender)
      get :new, reply_id: previous.id
      expect(response.status).to eq(200)
      expect(assigns(:message).parent_id).to eq(previous.id)
      expect(assigns(:message).subject).to eq("Re: #{previous.subject}")
    end

    it "handles replying to your own message" do
      original = create(:message)
      previous = create(:message, parent_id: original.id, thread_id: original.id, recipient_id: original.sender_id, sender_id: original.recipient_id)
      login_as(previous.sender)
      get :new, reply_id: previous.id
      expect(response.status).to eq(200)
      expect(assigns(:message).parent_id).to eq(previous.id)
      expect(assigns(:message).subject).to eq("Re: #{previous.subject}")
      expect(assigns(:message).recipient_id).to eq(previous.recipient_id)
    end

    it "rejects provided parents without permission" do
      previous = create(:message)
      login
      get :new, reply_id: previous.id
      expect(response.status).to eq(200)
      expect(previous).not_to be_visible_to(assigns(:current_user))
      expect(flash[:error]).to eq('You do not have permission to reply to that message.')
      expect(assigns(:message).parent_id).to be_nil
      expect(assigns(:message).subject).to be_blank
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
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with invalid params" do
      login
      post :create, message: {}
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Your message could not be sent because of the following problems:")
      expect(assigns(:page_title)).to eq('Compose Message')
    end

    it "succeeds with valid recipient" do
      login
      recipient = create(:user)
      post :create, message: {subject: 'test', message: 'testing', recipient_id: recipient.id}
      expect(response).to redirect_to(messages_path(view: 'inbox'))
      expect(flash[:success]).to eq('Message sent!')
    end

    it "fails if you try to forward a message" do
      previous = create(:message)
      other_user = create(:user)
      login_as(previous.recipient)
      post :create, message: {subject: 'Re: ' + previous.subject, message: 'response', recipient_id: other_user.id}, parent_id: previous.id
      expect(flash[:error]).to eq('Forwarding is not yet implemented.')
      expect(assigns(:message).recipient_id).to be_nil
      expect(assigns(:page_title)).to eq('Compose Message')
    end

    it "fails with invalid parent" do
      login
      post :create, message: {subject: 'Re: Fake', message: 'response'}, parent_id: -1
      expect(flash[:error]).to eq('Parent could not be found.')
      expect(assigns(:message).parent).to be_nil
    end

    it "succeeds with valid parent" do
      previous = create(:message)
      login_as(previous.recipient)
      post :create, message: {subject: 'Re: ' + previous.subject, message: 'response'}, parent_id: previous.id
      expect(response).to redirect_to(messages_path(view: 'inbox'))
      expect(flash[:success]).to eq('Message sent!')
      expect(assigns(:message).sender_id).to eq(previous.recipient_id)
      expect(assigns(:message).recipient_id).to eq(previous.sender_id)
    end

    it "succeeds when replying to yourself" do
      previous = create(:message)
      login_as(previous.sender)
      post :create, message: {subject: 'Re: ' + previous.subject, message: 'response'}, parent_id: previous.id
      expect(response).to redirect_to(messages_path(view: 'inbox'))
      expect(flash[:success]).to eq('Message sent!')
      expect(assigns(:message).sender_id).to eq(previous.sender_id)
      expect(assigns(:message).recipient_id).to eq(previous.recipient_id)
    end

    context "preview" do
      skip
    end

    it "has more tests" do
      skip
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
      expect(assigns(:message)).to eq(message)
      expect(message.reload.unread?).to be_true
    end

    it "works for recipient" do
      message = create(:message)
      login_as(message.recipient)
      get :show, id: message.id
      expect(response).to have_http_status(200)
      expect(assigns(:message)).to eq(message)
      expect(message.reload.unread?).not_to be_true
    end

    it "does not remark the message read" do
      message = create(:message, unread: false)
      login_as(message.recipient)
      expect_any_instance_of(Message).not_to receive(:update_attributes)
      get :show, id: message.id
    end
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "marking read/unread" do
      it "handles invalid message ids" do
        skip
      end

      it "does not work for users without access" do
        skip
      end

      it "does not work for sender" do
        skip "not yet implemented"
      end

      it "works read for recipient" do
        skip
      end

      it "works unread for recipient" do
        skip
      end
    end

    context "marking important/unimportant" do
      it "handles invalid message ids" do
        login
        expect_any_instance_of(Message).not_to receive(:update_attributes)
        post :mark, marked_ids: ['nope', -1, '0'], commit: "Mark / Unmark Important"
      end

      it "does not work for users without access" do
        message = create(:message)
        login
        expect_any_instance_of(Message).not_to receive(:update_attributes)
        post :mark, marked_ids: [message.id.to_s], commit: "Mark / Unmark Important"
      end

      context "sender" do
        it "works for important" do
          message = create(:message)
          login_as(message.sender)
          expect(message.marked_outbox).not_to be_true
          post :mark, marked_ids: [message.id.to_s], commit: "Mark / Unmark Important"
          expect(message.reload.marked_outbox).to be_true
        end

        it "works for unimportant" do
          message = create(:message, marked_outbox: true)
          login_as(message.sender)
          expect(message.marked_outbox).to be_true
          post :mark, marked_ids: [message.id.to_s], commit: "Mark / Unmark Important"
          expect(message.reload.marked_outbox).not_to be_true
        end
      end

      context "recipient" do
        it "works for important" do
          message = create(:message)
          login_as(message.recipient)
          expect(message.marked_inbox).not_to be_true
          post :mark, marked_ids: [message.id.to_s], commit: "Mark / Unmark Important"
          expect(message.reload.marked_inbox).to be_true
        end

        it "works for unimportant" do
          message = create(:message, marked_inbox: true)
          login_as(message.recipient)
          expect(message.marked_inbox).to be_true
          post :mark, marked_ids: [message.id.to_s], commit: "Mark / Unmark Important"
          expect(message.reload.marked_inbox).not_to be_true
        end
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
