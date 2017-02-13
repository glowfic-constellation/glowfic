require "spec_helper"

RSpec.describe Api::V1::PostsController do
  describe "GET show" do
    it "requires valid post" do
      get :show, id: 0
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires access to post" do
      post = create(:post, privacy: Post::PRIVACY_PRIVATE)
      get :show, id: post.id
      expect(response).to have_http_status(403)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with valid post" do
      post = create(:post, num_replies: 2, with_icon: true, with_character: true)
      reply = create(:reply, post: post, with_character: true, with_icon: true)
      get :show, id: post.id
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(post.id)
      expect(response.json['icon']['id']).to eq(post.icon_id)
      expect(response.json['character']['id']).to eq(post.character_id)
      expect(response.json['replies'].size).to eq(3)
      expect(response.json['replies'][2]['id']).to eq(reply.id)
      expect(response.json['replies'][2]['icon']['id']).to eq(reply.icon_id)
      expect(response.json['replies'][2]['character']['id']).to eq(reply.character_id)
    end

    it "paginates" do
      post = create(:post, num_replies: 5, with_icon: true, with_character: true)
      get :show, id: post.id, per_page: 2, page: 3
      expect(response).to have_http_status(200)
      expect(response.headers['Per-Page'].to_i).to eq(2)
      expect(response.headers['Page'].to_i).to eq(3)
      expect(response.headers['Total'].to_i).to eq(5)
      expect(response.headers['Link']).not_to be_nil
      expect(response.json['replies'].size).to eq(1)
    end
  end
end
