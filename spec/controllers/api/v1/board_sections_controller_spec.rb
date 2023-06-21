RSpec.describe Api::V1::BoardSectionsController do
  describe "POST reorder" do
    let(:user) { create(:user) }
    let(:continuity) { create(:continuity, creator: user) }
    let(:continuity2) { create(:continuity, creator: user) }
    let(:section1) { create(:board_section, board: continuity) }
    let(:section2) { create(:board_section, board: continuity) }
    let(:section3) { create(:board_section, board: continuity) }
    let(:section4) { create(:board_section, board: continuity) }
    let(:section5) { create(:board_section, board: continuity2) }

    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires a continuity you have access to" do
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)

      section_ids = [section2.id, section1.id]

      api_login
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(403)
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
    end

    it "requires a single continuity" do
      section1
      section2 = create(:board_section, board: continuity2)
      section3 = create(:board_section, board: continuity2)

      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(0)
      expect(section3.reload.section_order).to eq(1)

      section_ids = [section3.id, section2.id, section1.id]
      api_login
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(422)
      expect(response.json['errors'][0]['message']).to eq('Sections must be from one continuity')
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(0)
      expect(section3.reload.section_order).to eq(1)
    end

    it "requires valid section ids" do
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      section_ids = [-1]

      api_login_as(continuity.creator)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(404)
      expect(response.json['errors'][0]['message']).to eq('Some sections could not be found: -1')
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
    end

    it "works for valid changes", :show_in_doc do
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      expect(section3.reload.section_order).to eq(2)
      expect(section4.reload.section_order).to eq(3)
      expect(section5.reload.section_order).to eq(0)

      section_ids = [section3.id, section1.id, section4.id, section2.id]

      api_login_as(continuity.creator)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(200)
      expect(response.json).to eq({ 'section_ids' => section_ids })
      expect(section1.reload.section_order).to eq(1)
      expect(section2.reload.section_order).to eq(3)
      expect(section3.reload.section_order).to eq(0)
      expect(section4.reload.section_order).to eq(2)
      expect(section5.reload.section_order).to eq(0)
    end

    it "works when specifying valid subset", :show_in_doc do
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      expect(section3.reload.section_order).to eq(2)
      expect(section4.reload.section_order).to eq(3)
      expect(section5.reload.section_order).to eq(0)

      section_ids = [section3.id, section1.id]

      api_login_as(continuity.creator)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(200)
      expect(response.json).to eq({ 'section_ids' => [section3.id, section1.id, section2.id, section4.id] })
      expect(section1.reload.section_order).to eq(1)
      expect(section2.reload.section_order).to eq(2)
      expect(section3.reload.section_order).to eq(0)
      expect(section4.reload.section_order).to eq(3)
      expect(section5.reload.section_order).to eq(0)
    end
  end
end
