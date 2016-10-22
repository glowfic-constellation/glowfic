require "spec_helper"

RSpec.describe MessagesController do
  describe "GET index" do
    it "requires login" do
      get :index
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "assigns correct inbox variables" do
      user = create(:user)
      login_as(user)
      messages = 4.times.collect do create(:message, recipient: user) end
      get :index
      expect(response.status).to eq(200)
      expect(assigns(:view)).to eq('inbox')
      expect(assigns(:page_title)).to eq('Inbox')
      expect(assigns(:messages)).to match_array(messages)
    end

    it "assigns correct outbox variables" do
      user = create(:user)
      login_as(user)
      messages = 4.times.collect do create(:message, sender: user) end
      get :index, view: 'outbox'
      expect(response.status).to eq(200)
      expect(assigns(:view)).to eq('outbox')
      expect(assigns(:page_title)).to eq('Outbox')
      expect(assigns(:messages)).to match_array(messages)
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response.status).to eq(302)
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
    it "has more tests" do
      skip
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
