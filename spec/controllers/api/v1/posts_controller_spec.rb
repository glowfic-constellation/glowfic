require "spec_helper"

RSpec.describe Api::V1::PostsController do
  describe "GET show" do
    it "requires valid post", :show_in_doc do
      get :show, id: 0
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires access to post", :show_in_doc do
      post = create(:post, privacy: Post::PRIVACY_PRIVATE)
      get :show, id: post.id
      expect(response).to have_http_status(403)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with valid post", :show_in_doc do
      calias = create(:alias)
      post = create(:post, user: calias.character.user, with_icon: true, character: calias.character, character_alias: calias)
      expect(calias.name).not_to eq(calias.character.name)
      get :show, id: post.id
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(post.id)
      expect(response.json['icon']['id']).to eq(post.icon_id)
      expect(response.json['character']['id']).to eq(post.character_id)
      expect(response.json['character']['name']).to eq(calias.character.name)
      expect(response.json['character_name']).to eq(calias.name)
    end
  end
end
