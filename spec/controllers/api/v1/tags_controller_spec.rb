RSpec.describe Api::V1::TagsController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      it "should support label search", show_in_doc: in_doc do
        tag = create(:label)
        get :index, params: { q: tag.name, t: 'Label' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support setting search", show_in_doc: in_doc do
        tag = create(:setting)
        get :index, params: { q: tag.name, t: 'Setting' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support content warning search", show_in_doc: in_doc do
        tag = create(:content_warning)
        get :index, params: { q: tag.name, t: 'ContentWarning' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support gallery group search" do
        tag = create(:gallery_group)
        get :index, params: { q: tag.name, t: 'GalleryGroup' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should handle invalid input", show_in_doc: in_doc do
        get :index, params: { t: 'b' }
        expect(response).to have_http_status(422)
        expect(response.json).to have_key('errors')
        expect(response.json['errors'].first['message']).to include("Invalid parameter 't'")
      end

      context "in gallery group search with user_id" do
        it "should not display unused tags" do
          user = create(:user)
          ungrouped_tag = create(:gallery_group)
          get :index, params: { q: ungrouped_tag.name, t: 'GalleryGroup', user_id: user.id }
          expect(response).to have_http_status(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to eq([])
        end

        it "should display tags used on galleries" do
          user = create(:user)
          gal_grouped_tag = create(:gallery_group)
          create(:gallery, user: user, gallery_groups: [gal_grouped_tag])
          get :index, params: { q: gal_grouped_tag.name, t: 'GalleryGroup', user_id: user.id }
          expect(response).to have_http_status(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(gal_grouped_tag.as_json.stringify_keys)
        end

        it "should display tags used on characters" do
          user = create(:user)
          char_grouped_tag = create(:gallery_group)
          create(:character, user: user, gallery_groups: [char_grouped_tag])
          get :index, params: { q: char_grouped_tag.name, t: 'GalleryGroup', user_id: user.id }
          expect(response).to have_http_status(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(char_grouped_tag.as_json.stringify_keys)
        end
      end

      it "should exclude given setting", show_in_doc: in_doc do
        setting1 = create(:setting)
        setting2 = create(:setting)
        get :index, params: { t: 'Setting', tag_id: setting1.id }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(setting2.as_json.stringify_keys)
      end
    end

    context "when logged in" do
      before(:each) { api_login }

      it_behaves_like "index.json", false
    end

    context "when logged out" do
      it_behaves_like "index.json", true
    end
  end

  describe "GET show" do
    it "should support getting gallery groups with gallery IDs", :show_in_doc do
      user = create(:user)
      group = create(:gallery_group)
      galleries = create_list(:gallery, 2, user: user, gallery_groups: [group])
      create(:gallery, gallery_groups: [group])
      get :show, params: { id: group.id, user_id: user.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(group.id)
      expect(response.json['text']).to eq(group.name)
      expect(response.json['gallery_ids']).to match_array(galleries.map(&:id))
    end

    [:setting, :label, :content_warning].each do |type|
      it "should support getting #{type} tags" do
        tag = create(type) # rubocop:disable Rails/SaveBang
        get :show, params: { id: tag.id }
        expect(response).to have_http_status(200)
        expect(response.json['id']).to eq(tag.id)
      end
    end

    it "should handle invalid tag", :show_in_doc do
      get :show, params: { id: 99 }
      expect(response).to have_http_status(404)
      expect(response.json).to have_key('errors')
      expect(response.json['errors'][0]['message']).to eq("Tag could not be found")
    end
  end
end
