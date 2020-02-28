require "spec_helper"

RSpec.describe Api::V1::IndexPostsController do
  describe "POST reorder" do
    let!(:user) { create(:user) }
    let!(:index) { create(:index, user: user) }
    let!(:index2) { create(:index, user: user) }

    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    context "without index_section_id" do
      let!(:index_post1) { create(:index_post, index: index) }
      let!(:index_post2) { create(:index_post, index: index) }
      let!(:index_post3) { create(:index_post, index: index) }
      let!(:index_post4) { create(:index_post, index: index) }
      let!(:index_post5) { create(:index_post, index: index2) }

      it "requires a index you have access to" do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)

        post_ids = [index_post2, index_post1].map(&:id)

        login
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(403)
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
      end

      it "requires a single index without index_section_id" do
        index_post6 = create(:index_post, index: index2)

        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post5.reload.section_order).to eq(0)
        expect(index_post6.reload.section_order).to eq(1)

        post_ids = [index_post6, index_post5, index_post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one index')
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post5.reload.section_order).to eq(0)
        expect(index_post6.reload.section_order).to eq(1)
      end

      it "requires index_section_id if posts in index_section" do
        index_section = create(:index_section, index: index)
        index_post1 = create(:index_post, index: index, index_section: index_section)
        index_post2 = create(:index_post, index: index, index_section: index_section)

        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)

        post_ids = [index_post2, index_post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the index, or no section')
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
      end

      it "requires valid post_ids" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [-1]
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(404)
        expect(response.json['errors'][0]['message']).to eq('Some posts could not be found: -1')
      end

      it "works for valid changes", :show_in_doc do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
        expect(index_post3.reload.section_order).to eq(2)
        expect(index_post4.reload.section_order).to eq(3)
        expect(index_post5.reload.section_order).to eq(0)

        post_ids = [index_post3, index_post1, index_post4, index_post2].map(&:id)

        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => post_ids})
        expect(index_post1.reload.section_order).to eq(1)
        expect(index_post2.reload.section_order).to eq(3)
        expect(index_post3.reload.section_order).to eq(0)
        expect(index_post4.reload.section_order).to eq(2)
        expect(index_post5.reload.section_order).to eq(0)
      end

      it "works when specifying valid subset", :show_in_doc do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
        expect(index_post3.reload.section_order).to eq(2)
        expect(index_post4.reload.section_order).to eq(3)
        expect(index_post5.reload.section_order).to eq(0)

        post_ids = [index_post3, index_post1].map(&:id)

        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => [index_post3, index_post1, index_post2, index_post4].map(&:id)})
        expect(index_post1.reload.section_order).to eq(1)
        expect(index_post2.reload.section_order).to eq(2)
        expect(index_post3.reload.section_order).to eq(0)
        expect(index_post4.reload.section_order).to eq(3)
        expect(index_post5.reload.section_order).to eq(0)
      end
    end

    context "with index_section_id" do
      let!(:index_section) { create(:index_section, index: index)}
      let!(:index_section2) { create(:index_section, index: index)}
      let!(:index_post1) { create(:index_post, index: index, index_section: index_section) }
      let!(:index_post2) { create(:index_post, index: index, index_section: index_section) }
      let!(:index_post3) { create(:index_post, index: index, index_section: index_section) }
      let!(:index_post4) { create(:index_post, index: index, index_section: index_section) }
      let!(:index_post5) { create(:index_post, index: index, index_section: index_section2) }

      it "requires a index you have access to" do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)

        post_ids = [index_post2, index_post1].map(&:id)

        login
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section.id }
        expect(response).to have_http_status(403)
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
      end

      it "requires a single section" do
        index_post6 = create(:index_post, index_id: index, index_section: index_section2)

        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post5.reload.section_order).to eq(0)
        expect(index_post6.reload.section_order).to eq(1)

        post_ids = [index_post6, index_post5, index_post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section.id }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the index, or no section')
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post5.reload.section_order).to eq(0)
        expect(index_post6.reload.section_order).to eq(1)
      end

      it "requires valid section id" do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)

        post_ids = [index_post2, index_post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: 0 }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the index, or no section')
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
      end

      it "requires correct section id" do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
        expect(index_post3.reload.section_order).to eq(2)

        post_ids = [index_post3, index_post2].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section2.id }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the index, or no section')
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
        expect(index_post3.reload.section_order).to eq(2)
      end

      it "requires no section_id if posts not in section" do
        index_post1 = create(:index_post, index: index)
        index_post2 = create(:index_post, index: index)

        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)

        post_ids = [index_post2, index_post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section.id }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the index, or no section')
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
      end

      it "requires valid post_ids" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [-1]
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section.id }
        expect(response).to have_http_status(404)
        expect(response.json['errors'][0]['message']).to eq('Some posts could not be found: -1')
      end

      it "works for valid changes", :show_in_doc do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
        expect(index_post3.reload.section_order).to eq(2)
        expect(index_post4.reload.section_order).to eq(3)
        expect(index_post5.reload.section_order).to eq(0)

        post_ids = [index_post3, index_post1, index_post4, index_post2].map(&:id)

        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section.id }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => post_ids})
        expect(index_post1.reload.section_order).to eq(1)
        expect(index_post2.reload.section_order).to eq(3)
        expect(index_post3.reload.section_order).to eq(0)
        expect(index_post4.reload.section_order).to eq(2)
        expect(index_post5.reload.section_order).to eq(0)
      end

      it "works when specifying valid subset", :show_in_doc do
        expect(index_post1.reload.section_order).to eq(0)
        expect(index_post2.reload.section_order).to eq(1)
        expect(index_post3.reload.section_order).to eq(2)
        expect(index_post4.reload.section_order).to eq(3)
        expect(index_post5.reload.section_order).to eq(0)

        post_ids = [index_post3, index_post1].map(&:id)

        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: index_section.id }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => [index_post3, index_post1, index_post2, index_post4].map(&:id)})
        expect(index_post1.reload.section_order).to eq(1)
        expect(index_post2.reload.section_order).to eq(2)
        expect(index_post3.reload.section_order).to eq(0)
        expect(index_post4.reload.section_order).to eq(3)
        expect(index_post5.reload.section_order).to eq(0)
      end
    end
  end
end
