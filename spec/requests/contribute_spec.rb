RSpec.describe "Contribute" do
  it "renders the page" do
    get "/contribute"
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
      expect(response.body).to include("Contribute to the Constellation")
    end
  end
end
