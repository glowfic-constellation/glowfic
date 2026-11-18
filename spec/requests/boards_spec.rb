RSpec.describe "Continuities" do
  describe "show" do
    let(:board) { create(:board, description: 'to display') }

    it "loads the board logged out" do
      board.update!(description: '') # for branch testing
      get "/boards/#{board.id}"
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end

    it "loads the board logged in" do
      login(board.creator)
      create(:board_section, board: board, description: 'section display')
      get "/boards/#{board.id}"
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end

    it "shows unfavorite" do
      user = login
      create(:favorite, user: user, favorite: board)
      get "/boards/#{board.id}"
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
      expect(response.body).to include("Unfavorite")
    end

    it "includes posts and pagination" do
      create(:post, board: board, user: board.creator)
      create_list(:board_section, 25, board: board)
      section = create(:board_section, board: board)
      create(:post, section: section, board: board, user: board.creator)
      get "/boards/#{board.id}?page=2"
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end
  end

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

  describe "search" do
    it "works" do
      create(:board, name: "Sample board")
      create(:board, name: "Other board")

      get "/boards/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Continuities")
      end

      get "/boards/search?name=Sample&commit=Search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Continuities")
        expect(response.body).to include("Sample board")
        expect(response.body).not_to include("Other board")
      end
    end
  end

  describe '#show' do
    let(:creator) { create(:user) }
    let(:author) { create(:user) }
    let(:reader) { create(:reader_user) }
    let(:cont) { create(:board, creator: creator, authors: [author], authors_locked: true) }
    let(:body) { response.parsed_body }

    context 'with a sectioned continuity' do
      let!(:section) { create(:board_section, board: cont) }

      before(:each) do
        create_list(:post, 2, user: author, board: cont, section: section)
        cont.reload
      end

      it 'works' do
        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('posts/_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          expect(body.at_css('.table-title').text.strip).to eq(cont.name)
          expect(body.at_css('.continuity-header').text).to eq(section.name)

          cont.posts.ordered_in_section.each_with_index do |post, i|
            expect(body.css('.post-subject')[i].text.strip).to eq(post.subject)
          end
        end
      end

      it 'works with no posts' do
        cont.posts.each(&:destroy!)

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).not_to render_template('posts/_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          expect(body.at_css('.table-title').text.strip).to eq(cont.name)
          expect(body.at_css('.continuity-header').text).to eq(section.name)

          expect(body.css('.post-subject')).to be_empty
          expect(body.at_css('.no-posts').text).to eq('— No posts yet —')
        end
      end

      it 'works with many sections' do
        sections = create_list(:board_section, 27, board: cont)
        sections.each { |s| create_list(:post, 2, user: author, board: cont, section: s) }
        create_list(:post, 2, user: author, board: cont)
        sections.prepend(section)

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('posts/_list_item')
          expect(response).to render_template('posts/_paginator')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          expect(body.at_css('.table-title').text.strip).to eq(cont.name)

          sections[0..24].each_with_index do |section, i|
            expect(body.css('.continuity-header')[i].text).to eq(section.name)

            section.posts.ordered_in_section.each_with_index do |post, j|
              expect(body.css('.post-subject')[(i * 2) + j].text.strip).to eq(post.subject)
            end
          end

          expect(body.css('.post-subject')[51]).to be_nil
          expect(text_clean(body.at_css('.paginator'))).to eq('Total: 28 ‹ Previous 1 2 Next › « First ‹ Previous 1 of 2 Next › Last »')
        end
      end

      it 'works with a complex continuity' do
        cont.posts.each(&:destroy!)
        cont.update!(description: 'sample description')
        section.update!(description: 'sample description 0')
        1.upto(5) { |i| create(:board_section, board: cont, description: "sample description #{i}") }
        cont.reload

        cont.board_sections.each do |section|
          create(:post, user: author, board: cont, section: section)
          create(:post, user: creator, board: cont, section: section)
          create(:post, user: author, board: cont, section: section)
        end

        create(:post, user: author, board: cont)
        create(:post, user: creator, board: cont)
        create(:post, user: author, board: cont)
        create(:post, user: creator, board: cont)

        cont.reload

        login

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('posts/_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to include('You are now logged in')

          expect(text_clean(body.at_css('.table-title'))).to eq("#{cont.name} Favorite")
          expect(body.css('.written-content')[0].text).to eq(cont.description)

          cont.board_sections.each_with_index do |section, i|
            expect(body.css('.continuity-header')[i].text).to eq(section.name)
            expect(body.css('.written-content')[i + 1].text).to eq(section.description)

            section.posts.ordered_in_section.each_with_index do |post, j|
              expect(body.css('.post-subject')[(i * 3) + j].text.strip).to eq(post.subject)
            end
          end

          section_num = cont.board_sections.size
          ind = section_num * 3
          cont.posts.where(section_id: nil).ordered_in_section.each_with_index do |post, i|
            expect(body.css('.post-subject')[ind + i].text.strip).to eq(post.subject)
          end

          expect(body.css('.continuity-spacer').size).to eq(section_num + 1)
        end
      end
    end

    context 'with an unsectioned continuity' do
      before(:each) do
        create_list(:post, 3, user: author, board: cont)
        cont.reload
      end

      it 'works' do
        cont.update!(authors_locked: false)

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('posts/_list')
          expect(response).to render_template('posts/_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          expect(body.at_css('.table-title').text.strip).to eq(cont.name)

          cont.posts.ordered.each_with_index do |post, i|
            expect(body.css('.post-subject')[i].text.strip).to eq(post.subject)
          end
        end
      end

      it 'works with a complex continuity' do
        create_list(:post, 15, user: author, board: cont)
        create_list(:post, 10, user: creator, board: cont)
        create_list(:post, 2, user: author, board: cont)
        cont.update!(description: 'sample description')
        cont.reload

        login

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('posts/_list')
          expect(response).to render_template('posts/_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to include('You are now logged in')

          expect(text_clean(body.at_css('.table-title'))).to eq("#{cont.name} Favorite")
          expect(body.at_css('.written-content').text.strip).to eq(cont.description)

          cont.posts.ordered_in_section[0..24].each_with_index do |post, i|
            expect(body.css('.post-subject')[i].text.strip).to eq(post.subject)
          end

          expect(text_clean(body.at_css('.paginator'))).to eq('Total: 30 ‹ Previous 1 2 Next › « First ‹ Previous 1 of 2 Next › Last »')
        end
      end

      it 'works with an empty continuity' do
        cont.posts.each(&:destroy!)

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('posts/_list')
          expect(response).not_to render_template('posts/_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          expect(body.at_css('.table-title').text.strip).to eq(cont.name)

          expect(body.css('.post-subject')).to be_empty
          expect(body.at_css('.no-posts').text).to eq('— No posts yet —')
        end
      end
    end

    context 'linkboxes' do
      shared_examples 'open or closed' do
        it 'has no buttons if logged out' do
          get "/boards/#{cont.id}"

          aggregate_failures do
            expect(response).to have_http_status(200)
            expect(response).to render_template(:show)

            expect(flash[:error]).to be_nil
            expect(flash[:success]).to be_nil

            expect(body.at_css('.table-title').text.strip).to eq(cont.name)
          end
        end

        it 'only has favorite for reader users' do
          login(reader)

          get "/boards/#{cont.id}"

          aggregate_failures do
            expect(response).to have_http_status(200)
            expect(response).to render_template(:show)

            expect(flash[:error]).to be_nil
            expect(flash[:success]).to include('You are now logged in')

            expect(text_clean(body.at_css('.table-title'))).to eq("#{cont.name} Favorite")
          end
        end

        it 'has buttons for coauthors' do
          login(author)

          get "/boards/#{cont.id}"

          aggregate_failures do
            expect(response).to have_http_status(200)
            expect(response).to render_template(:show)

            expect(flash[:error]).to be_nil
            expect(flash[:success]).to include('You are now logged in')

            buttons = ['+ New Post', '+ New Section', 'Edit', 'x Delete', 'Favorite']
            title = ([cont.name] + buttons).join(' ')
            expect(text_clean(body.at_css('.table-title'))).to eq(title)
          end
        end

        it 'has buttons for creator' do
          login(creator)

          get "/boards/#{cont.id}"

          aggregate_failures do
            expect(response).to have_http_status(200)
            expect(response).to render_template(:show)

            expect(flash[:error]).to be_nil
            expect(flash[:success]).to include('You are now logged in')

            buttons = ['+ New Post', '+ New Section', 'Edit', 'x Delete', 'Favorite']
            title = ([cont.name] + buttons).join(' ')
            expect(text_clean(body.at_css('.table-title'))).to eq(title)
          end
        end
      end

      context 'with an open continuity' do
        before(:each) { cont.update!(authors_locked: false) }

        include_examples 'open or closed'

        it 'only has new post and favorite for full users' do
          login

          get "/boards/#{cont.id}"

          aggregate_failures do
            expect(response).to have_http_status(200)
            expect(response).to render_template(:show)

            expect(flash[:error]).to be_nil
            expect(flash[:success]).to include('You are now logged in')

            buttons = ['+ New Post', 'Favorite']
            title = ([cont.name] + buttons).join(' ')
            expect(text_clean(body.at_css('.table-title'))).to eq(title)
          end
        end
      end

      context 'with a closed continuity' do
        include_examples 'open or closed'

        it 'only has favorite for full users' do
          login

          get "/boards/#{cont.id}"

          aggregate_failures do
            expect(response).to have_http_status(200)
            expect(response).to render_template(:show)

            expect(flash[:error]).to be_nil
            expect(flash[:success]).to include('You are now logged in')

            title = [cont.name, 'Favorite'].join(' ')
            expect(text_clean(body.at_css('.table-title'))).to eq(title)
          end
        end
      end

      it 'has unfavorite with a favorite' do
        user = create(:user)
        create(:favorite, user: user, favorite: cont)
        login(user)

        get "/boards/#{cont.id}"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to include('You are now logged in')

          title = [cont.name, 'Unfavorite'].join(' ')
          expect(text_clean(body.at_css('.table-title'))).to eq(title)
        end
      end
    end
  end
end
