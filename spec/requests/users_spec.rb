RSpec.describe "Users" do
  describe "creation" do
    it "creates a new reader-mode user and logs in" do
      get "/users/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Sign Up")
      end

      post "/users", params: {
        user: {
          username: "John Doe",
          email: "john.doe@example.com",
          password: "password",
          password_confirmation: "password",
        },
        addition: 14,
        tos: true,
      }

      aggregate_failures do
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to be_nil
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("John Doe")
        expect(response.body).to include("Log out")
        expect(response.body).to include("User created! You have been logged in.")
      end
    end
  end
end
