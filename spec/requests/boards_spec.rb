RSpec.describe "Continuities" do
  describe "creation" do
    it "creates a new board and shows on the boards list" do
      login
      get "/boards/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Create Continuity")
      end

      expect {
        post "/boards", params: {
          board: {
            name: "Sample",
            coauthor_ids: [],
            cameo_ids: [],
            authors_locked: true,
            description: "Sample board description",
          },
        }
      }.to change { Board.count }.by(1)

      aggregate_failures do
        expect(response).to redirect_to(continuities_path)
        expect(flash[:error]).to be_nil
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("Sample")
        expect(response.body).to include("Continuity created.")
      end

      user = Board.last
      get "/boards/#{user.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Sample")
        expect(response.body).to include("+ New Post")
      end
    end

    it "creates board sections and shows on the board" do
      user = login
      board = create(:board, name: "Sample board", creator: user)
      create(:post, board: board, user: user, subject: "Sample post")

      # create new section
      get "/boards/#{board.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include("+ New Section")
      end

      get "/board_sections/new?board_id=#{board.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Create Sample board Section")
      end

      expect {
        post "/board_sections", params: {
          board_section: {
            name: "Sample section",
            board_id: board.id,
          },
        }
      }.to change { BoardSection.count }.by(1)
      section = BoardSection.last

      aggregate_failures do
        expect(response).to redirect_to(edit_continuity_path(board))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to include("New section, Sample section")
      end
      follow_redirect!

      # board edit page allows reordering sections and posts
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Sample board")
        expect(response.body).to include("Edit Continuity")
        expect(response.body).to include("Organize Continuity Sections")
        expect(response.body).to include("Sample section")
        expect(response.body).to include("Organize Unsectioned Posts")
      end

      # create a quick post for the section
      create(:post, board: board, user: user, section: section, subject: "Other sample post")

      # view section
      get "/board_sections/#{section.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Sample section")
        expect(response.body).to include("Other sample post")
        expect(response.body).to include("Edit")
      end

      # edit section
      get "/board_sections/#{section.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Sample section")
        expect(response.body).to include("Organize Section Posts")
      end

      patch "/board_sections/#{section.id}", params: {
        board_section: {
          name: "Updated section name",
        },
      }

      aggregate_failures do
        expect(response).to redirect_to(board_section_path(section))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to include("Section updated.")
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Updated section name")
      end
    end
  end
end
