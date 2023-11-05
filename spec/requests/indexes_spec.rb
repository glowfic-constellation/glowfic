RSpec.describe "Index" do
  describe "management" do
    it "creates and edits index components" do
      user = login
      get "/indexes/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("New Index")
      end

      post "/indexes", params: {
        index: {
          name: "test index 1",
        },
      }
      index = Index.last
      aggregate_failures do
        expect(response).to redirect_to(index_path(index))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Index created.")

        expect(index.name).to eq("test index 1")
      end

      # check index shows on index list
      get "/indexes"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("test index 1")
      end

      # edit this index
      get "/indexes/#{index.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Index")
      end

      patch "/indexes/#{index.id}", params: {
        index: {
          name: "test index 2",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(index_path(index))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Index updated.")
      end

      # create an index section for this index
      get "/index_sections/new", params: {
        index_id: index.id,
      }
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("New Section")
      end

      post "/index_sections", params: {
        index_section: {
          name: "test section 1",
          index_id: index.id,
        },
      }
      section = IndexSection.last
      aggregate_failures do
        expect(response).to redirect_to(index_path(index))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("New section, test section 1, created for test index 2.")

        expect(section.name).to eq("test section 1")
        expect(section.index_id).to eq(index.id)
      end

      # show index section
      get "/index_sections/#{section.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("test section 1")
      end

      # edit this index section
      get "/index_sections/#{section.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Index Section")
      end

      patch "/index_sections/#{section.id}", params: {
        index_section: {
          name: "test section 2",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(index_path(index))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Index section updated.")
      end

      # create an index post for this index section
      get "/index_posts/new", params: {
        index_id: index.id,
        index_section_id: section.id,
      }
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Add Post to Index")
      end

      new_post = create(:post, user: user)
      post "/index_posts", params: {
        index_post: {
          post_id: new_post.id,
          index_section_id: section.id,
          description: "test description 1",
        },
      }
      ipost = IndexPost.last
      aggregate_failures do
        expect(response).to redirect_to(index_path(index))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Post added to index.")

        expect(ipost.post_id).to eq(new_post.id)
        expect(ipost.index_section_id).to eq(section.id)
      end

      # edit this index post
      get "/index_posts/#{ipost.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Post")
      end

      patch "/index_posts/#{ipost.id}", params: {
        index_post: {
          description: "test description 2",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(index_path(index))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Index post updated.")
      end

      # load the index
      get "/indexes/#{index.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("test index 2")
        expect(response.body).to include("test section 2")
        expect(response.body).to include(new_post.subject)
        expect(response.body).to include("test description 2")
      end
    end
  end
end
