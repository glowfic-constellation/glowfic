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

    it "handles provided parent" do
      previous = create(:message)
      login_as(previous.sender)
      get :new, reply_id: previous.id
      expect(response.status).to eq(200)
      expect(assigns(:message).parent_id).to eq(previous.id)
      expect(assigns(:message).subject).to eq("Re: #{previous.subject}")
    end

    it "ignores provided parents without permission" do
      previous = create(:message)
      login
      get :new, reply_id: previous.id
      expect(response.status).to eq(200)
      expect(previous).not_to be_visible_to(assigns(:current_user))
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

  describe "PUT update" do
    it "has more tests" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "has more tests" do
      skip
    end
  end

  describe "POST mark" do
    it "has more tests" do
      skip
    end
  end
end
