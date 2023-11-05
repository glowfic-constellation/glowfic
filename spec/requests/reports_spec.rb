RSpec.describe "Reports" do
  it "renders the index" do
    login
    get "/reports"
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
    end
  end

  skip "renders the daily view" do
    skip "already tested in controllers specs"
  end

  it "renders the monthly view" do
    login

    create(:post, subject: "New today")
    present = create(:post, subject: "Old post")
    present.update!(created_at: 1.month.ago.end_of_month, tagged_at: 1.month.ago.end_of_month)

    get "/reports/monthly"
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
      expect(response.body).to include("Monthly Report")
      expect(response.body).to include("Old post")
      expect(response.body).not_to include("New today")
    end
  end
end
