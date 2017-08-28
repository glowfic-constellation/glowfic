require "spec_helper"

RSpec.describe Api::V1::TagsController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      it "should support label search", show_in_doc: in_doc do
        tag = create(:label)
        get :index, q: tag.name, t: 'Label'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support setting search", show_in_doc: in_doc do
        tag = create(:setting)
        get :index, q: tag.name, t: 'Setting'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support content warning search", show_in_doc: in_doc do
        tag = create(:content_warning)
        get :index, q: tag.name, t: 'ContentWarning'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support gallery group search" do
        tag = create(:gallery_group)
        get :index, q: tag.name, t: 'GalleryGroup'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should handle invalid input", show_in_doc: in_doc do
        get :index, t: 'b'
        expect(response).to have_http_status(422)
        expect(response.json).to have_key('errors')
        expect(response.json['errors'].first).to include("Invalid parameter 't'")
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }
      before(:each) { login_as(user) }
      it_behaves_like "index.json", false

      context "in gallery group search with user_id" do
        it "should not display unused tags" do
          ungrouped_tag = create(:gallery_group)
          get :index, q: ungrouped_tag.name, t: 'GalleryGroup', user_id: user.id
          expect(response).to have_http_status(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to eq([])
        end

        it "should display tags used on characters" do
          char_grouped_tag = create(:gallery_group)
          create(:character, user: user, gallery_groups: [char_grouped_tag])
          get :index, q: char_grouped_tag.name, t: 'GalleryGroup', user_id: user.id
          expect(response).to have_http_status(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(char_grouped_tag.as_json.stringify_keys)
        end

        it "should display tags used on galleries" do
          gal_grouped_tag = create(:gallery_group)
          create(:gallery, user: user, gallery_groups: [gal_grouped_tag])
          get :index, q: gal_grouped_tag.name, t: 'GalleryGroup', user_id: user.id
          expect(response).to have_http_status(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(gal_grouped_tag.as_json.stringify_keys)
        end
      end
    end

    context "when logged out" do
      it_behaves_like "index.json", true
    end
  end
end
