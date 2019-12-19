require "spec_helper"

RSpec.describe Api::V1::SubcontinuitiesController do
  describe "POST reorder" do
    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires a continuity you have access to" do
      continuity = create(:continuity)
      subcontinuity1 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity2 = create(:subcontinuity, continuity_id: continuity.id)
      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(1)

      section_ids = [subcontinuity2.id, subcontinuity1.id]

      login
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(403)
      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(1)
    end

    it "requires a single continuity" do
      user = create(:user)
      continuity1 = create(:continuity, creator: user)
      continuity2 = create(:continuity, creator: user)
      subcontinuity1 = create(:subcontinuity, continuity_id: continuity1.id)
      subcontinuity2 = create(:subcontinuity, continuity_id: continuity2.id)
      subcontinuity3 = create(:subcontinuity, continuity_id: continuity2.id)

      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(0)
      expect(subcontinuity3.reload.section_order).to eq(1)

      section_ids = [subcontinuity3.id, subcontinuity2.id, subcontinuity1.id]
      login_as(user)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(422)
      expect(response.json['errors'][0]['message']).to eq('Sections must be from one continuity')
      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(0)
      expect(subcontinuity3.reload.section_order).to eq(1)
    end

    it "requires valid section ids" do
      continuity = create(:continuity)
      subcontinuity1 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity2 = create(:subcontinuity, continuity_id: continuity.id)
      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(1)
      section_ids = [-1]

      login_as(continuity.creator)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(404)
      expect(response.json['errors'][0]['message']).to eq('Some sections could not be found: -1')
      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(1)
    end

    it "works for valid changes", :show_in_doc do
      continuity = create(:continuity)
      continuity2 = create(:continuity, creator: continuity.creator)
      subcontinuity1 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity2 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity3 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity4 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity5 = create(:subcontinuity, continuity_id: continuity2.id)

      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(1)
      expect(subcontinuity3.reload.section_order).to eq(2)
      expect(subcontinuity4.reload.section_order).to eq(3)
      expect(subcontinuity5.reload.section_order).to eq(0)

      section_ids = [subcontinuity3.id, subcontinuity1.id, subcontinuity4.id, subcontinuity2.id]

      login_as(continuity.creator)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(200)
      expect(response.json).to eq({'section_ids' => section_ids})
      expect(subcontinuity1.reload.section_order).to eq(1)
      expect(subcontinuity2.reload.section_order).to eq(3)
      expect(subcontinuity3.reload.section_order).to eq(0)
      expect(subcontinuity4.reload.section_order).to eq(2)
      expect(subcontinuity5.reload.section_order).to eq(0)
    end

    it "works when specifying valid subset", :show_in_doc do
      continuity = create(:continuity)
      continuity2 = create(:continuity, creator: continuity.creator)
      subcontinuity1 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity2 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity3 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity4 = create(:subcontinuity, continuity_id: continuity.id)
      subcontinuity5 = create(:subcontinuity, continuity_id: continuity2.id)

      expect(subcontinuity1.reload.section_order).to eq(0)
      expect(subcontinuity2.reload.section_order).to eq(1)
      expect(subcontinuity3.reload.section_order).to eq(2)
      expect(subcontinuity4.reload.section_order).to eq(3)
      expect(subcontinuity5.reload.section_order).to eq(0)

      section_ids = [subcontinuity3.id, subcontinuity1.id]

      login_as(continuity.creator)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(200)
      expect(response.json).to eq({'section_ids' => [subcontinuity3.id, subcontinuity1.id, subcontinuity2.id, subcontinuity4.id]})
      expect(subcontinuity1.reload.section_order).to eq(1)
      expect(subcontinuity2.reload.section_order).to eq(2)
      expect(subcontinuity3.reload.section_order).to eq(0)
      expect(subcontinuity4.reload.section_order).to eq(3)
      expect(subcontinuity5.reload.section_order).to eq(0)
    end
  end
end
