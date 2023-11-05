RSpec.describe "Gallery" do
  describe "search" do
    it "works" do
      get "/galleries/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
      end

      # TODO: perform a search when this is no longer under construction
    end
  end
end
