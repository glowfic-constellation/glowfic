RSpec.describe "Templates" do
  describe "editing" do
    it "updates a template" do
      user = login
      template = create(:template, user: user)
      get "/templates/#{template.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Template")
      end

      patch "/templates/#{template.id}", params: {
        template: {
          name: "test template 1",
          description: "Test description",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(template_path(template))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Template updated.")

        template.reload
        expect(template.name).to eq("test template 1")
        expect(template.description).to eq("Test description")
      end
    end
  end

  describe "search" do
    it "works" do
      get "/templates/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
      end

      # TODO: perform a search when this is no longer under construction
    end
  end
end
