RSpec.describe "Viewing a character" do
  let(:user) { create(:user, username: 'Example user') }
  let(:character) do
    default_icon = create(:icon, user: user, keyword: 'Default', url: 'https://example.com/image.png')
    icon2 = create(:icon, user: user, keyword: 'Test')
    gallery = create(:gallery, user: user, icons: [default_icon, icon2], name: 'Test gallery')
    setting = create(:setting, name: 'Example setting')
    create(:character, user: user, galleries: [gallery], default_icon: default_icon, name: 'Test char', settings: [setting], pb: 'Example person')
  end

  def expect_basic_character_page(char)
    visit character_path(char)

    aggregate_failures 'Info' do
      yield 'Info'

      within('.character-info-box') do
        expect(page).to have_selector('.character-name', exact_text: 'Test char')
        expect(page).to have_no_selector('.character-screenname')
        expect(page).to have_selector('.character-icon')
        expect(find('.character-icon img')[:src]).to eq('https://example.com/image.png')
      end

      within('.character-right-content-box') do
        expect(page).to have_no_selector('th', text: 'Nickname')
        expect(page).to have_no_selector('th', text: 'Template')

        expect(page).to have_selector('th', text: 'Facecast')
        within(row_for('Facecast')) do
          expect(page).to have_selector('.character-pb', text: 'Example person')
        end

        expect(page).to have_selector('th', text: 'Setting')
        within(row_for('Setting')) do
          expect(page).to have_link('Example setting')
        end

        expect(page).to have_no_selector('th', text: 'Description')
      end
    end

    within('.character-info-box') do
      click_link 'Galleries'
    end

    aggregate_failures 'Galleries' do
      yield 'Galleries'

      within('.character-right-content-box') do
        expect(page).to have_selector('.gallery-title', count: 1)
        expect(page).to have_selector('.gallery-title', exact_text: 'Test gallery')

        within('.gallery-icons') do
          expect(page).to have_selector('.gallery-icon', count: 2)
          expect(page).to have_selector('.gallery-icon', exact_text: 'Default')
          expect(page).to have_selector('.gallery-icon', exact_text: 'Test')
        end
      end
    end

    within('.character-info-box') do
      click_link 'Posts'
    end

    aggregate_failures 'Posts' do
      yield 'Posts'

      within('.character-right-content-box') do
        expect(page).to have_selector('th', exact_text: 'Recent Threads')
        expect(page).to have_selector('td', text: 'No posts yet')
      end
    end
  end

  scenario "View another user's basic character" do
    # Info page
    expect_basic_character_page(character) do |view|
      aggregate_failures do
        expect(page).to have_selector('.breadcrumbs', text: 'Test char » ' + view)
        within('.breadcrumbs') do
          expect(page).to have_link('Example user', href: user_path(user))
          expect(page).to have_link("Example user's Characters", href: user_characters_path(user))
        end

        expect(page).to have_no_link('Edit Character')
        expect(page).to have_no_link('Duplicate Character')
        expect(page).to have_no_link('Replace Character')
        expect(page).to have_no_link('Delete Character')
      end
    end
  end

  scenario "View another user's basic character while logged in" do
    login

    expect_basic_character_page(character) do |view|
      aggregate_failures do
        expect(page).to have_selector('.breadcrumbs', text: 'Test char » ' + view)
        within('.breadcrumbs') do
          expect(page).to have_link('Example user', href: user_path(user))
          expect(page).to have_link("Example user's Characters", href: user_characters_path(user))
        end

        expect(page).to have_no_link('Edit Character')
        expect(page).to have_no_link('Duplicate Character')
        expect(page).to have_no_link('Replace Character')
        expect(page).to have_no_link('Delete Character')
      end
    end
  end

  scenario "View another user's basic character as a mod" do
    login(create(:mod_user))

    expect_basic_character_page(character) do |view|
      aggregate_failures do
        expect(page).to have_selector('.breadcrumbs', text: 'Test char » ' + view)
        within('.breadcrumbs') do
          expect(page).to have_link('Example user', href: user_path(user))
          expect(page).to have_link("Example user's Characters", href: user_characters_path(user))
        end

        expect(page).to have_link('Edit Character')
        expect(page).to have_no_link('Duplicate Character')
        expect(page).to have_no_link('Replace Character')
        expect(page).to have_no_link('Delete Character')
      end
    end
  end

  scenario "View your own basic character" do
    login(user)

    expect_basic_character_page(character) do |view|
      aggregate_failures do
        expect(page).to have_selector('.breadcrumbs', text: 'Test char » ' + view)
        within('.breadcrumbs') do
          expect(page).to have_link("You", href: user_path(user))
          expect(page).to have_link("Your Characters", href: user_characters_path(user))
        end

        expect(page).to have_link('Edit Character')
        expect(page).to have_link('Duplicate Character')
        expect(page).to have_link('Replace Character')
        expect(page).to have_link('Delete Character')
      end
    end
  end

  scenario "View a galleryless character" do
    char = create(:character, user: user, name: 'Test char')

    login
    visit character_path(char)

    aggregate_failures do
      within('.character-info-box') do
        expect(page).to have_selector('.character-name', exact_text: 'Test char')
        expect(page).to have_no_selector('.character-screenname')

        expect(page).to have_no_selector('.character-icon')

        click_link 'Galleries'
      end

      expect(page).to have_selector('.character-right-content-box td', text: 'No galleries yet')
    end
  end

  scenario "View a character with a deleted user" do
    user = create(:user, deleted: true)
    char = create(:character, user: user, name: "Test char")

    visit character_path(char)

    aggregate_failures do
      expect(page).to have_selector('.breadcrumbs', text: 'Test char » ')
      within('.breadcrumbs') do
        expect(page).to have_no_link(href: user_path(user))
        expect(page).to have_text("(deleted user) » ")
      end
    end
  end

  scenario "View a complex character" do
    icon2_1 = create(:icon, user: user, keyword: 'Test B')
    icon2_2 = create(:icon, user: user, keyword: 'Test A')
    icon2_3 = create(:icon, user: user, keyword: 'Test C')
    icon1_1 = create(:icon, user: user, keyword: 'Test D', url: 'https://example.com/image2.png')
    group1 = create(:gallery_group, name: 'Group B')
    group2 = create(:gallery_group, name: 'Group A')
    group3 = create(:gallery_group, name: 'Group C')
    gallery2 = create(:gallery, user: user, icons: [icon2_1, icon2_3, icon2_2], gallery_groups: [group1, group3, group2], name: 'Gallery 2')
    gallery1 = create(:gallery, user: user, icons: [icon1_1], name: 'Gallery 1')
    template = create(:template, name: 'Example template')
    setting1 = create(:setting, name: 'Example setting')
    setting2 = create(:setting, name: 'Second setting')
    char = create(:character,
      user: user,
      name: 'Char Surname',
      screenname: 'just-a-char',
      nickname: 'Char',
      default_icon: icon1_1,
      galleries: [gallery2, gallery1],
      template: template,
      pb: 'Example PB',
      description: 'Basic desc',
      settings: [setting1, setting2],
    )
    create(:alias, character: char, name: 'Alias Person')
    post = create(:post, user: user, character: char, subject: 'Example post')
    post2 = create(:post, subject: 'Other post')
    create(:reply, post: post2, user: user, character: char)

    login

    visit character_path(char)

    # Info
    aggregate_failures 'Info' do
      within('.character-info-box') do
        expect(page).to have_selector('.character-name', exact_text: 'Char Surname')
        expect(page).to have_selector('.character-screenname', exact_text: 'just-a-char')
        expect(page).to have_selector('.character-icon')
        expect(find('.character-icon img')[:src]).to eq('https://example.com/image2.png')
      end

      within('.character-right-content-box') do
        expect(page).to have_selector('th', text: 'Nickname')
        within(row_for('Nickname')) do
          expect(page).to have_selector('.character-nickname', exact_text: 'Char')
        end

        within(row_for('Aliases')) do
          expect(page).to have_selector('.character-aliases', exact_text: 'Alias Person')
        end

        expect(page).to have_selector('th', text: 'Template')
        within(row_for('Template')) do
          expect(page).to have_selector('.character-template', exact_text: 'Example template')
          expect(page).to have_link('Example template', href: template_path(template))
        end

        expect(page).to have_selector('th', text: 'Facecast')
        within(row_for('Facecast')) do
          expect(page).to have_selector('.character-pb', text: 'Example PB')
        end

        expect(page).to have_selector('th', text: 'Setting')
        within(row_for('Setting')) do
          expect(page).to have_selector('.character-setting', exact_text: 'Example setting, Second setting')
          expect(page).to have_link('Example setting', href: tag_path(setting1))
          expect(page).to have_link('Second setting', href: tag_path(setting2))
        end

        expect(page).to have_selector('th', text: 'Description')
        within(row_for('Description')) do
          expect(page).to have_selector('.character-description', text: 'Basic desc')
        end
      end
    end

    within('.character-info-box') do
      click_link 'Galleries'
    end

    # Galleries
    aggregate_failures 'Galleries' do
      within('.character-right-content-box') do
        expect(page).to have_selector('.gallery-title', count: 2)
        expect(all('.gallery-title').map(&:text)).to eq(['Gallery 2', 'Gallery 1'])

        expect(page).to have_selector('.gallery-tags', count: 1)
        within('.gallery-tags') do
          expect(page).to have_text('Groups:')
          expect(page).to have_selector('.tag-item', count: 3)
          expect(all('.tag-item').map(&:text)).to eq(['Group B', 'Group C', 'Group A'])
        end

        icon_boxes = all('.gallery-icons')
        expect(icon_boxes.count).to eq(2)

        within(icon_boxes.first) do
          expect(page).to have_selector('.gallery-icon', count: 3)
          expect(all('.gallery-icon').map(&:text)).to eq(['Test A', 'Test B', 'Test C'])
        end

        within(icon_boxes.last) do
          expect(page).to have_selector('.gallery-icon', count: 1)
          expect(all('.gallery-icon').map(&:text)).to eq(['Test D'])
        end
      end
    end

    within('.character-info-box') do
      click_link 'Posts'
    end

    # Posts
    aggregate_failures 'Posts' do
      within('.character-right-content-box') do
        expect(page).to have_selector('.table-title', exact_text: 'Recent Threads')
        expect(page).to have_link('Example post', href: post_path(post))
        expect(page).to have_link('Other post', href: post_path(post2))
      end
    end
  end

  scenario "Viewing many character galleries", :js do # rubocop:disable RSpec/MultipleExpectations
    icons = Array.new(4) { |i| create(:icon, user: user, keyword: "Default#{i}", url: "https://example.com/image#{i}.png") }
    galleries = Array.new(4) { |i| create(:gallery, user: user, icons: [icons[i]], name: "Gallery #{i}") }
    group = create(:gallery_group, name: 'Group A')
    galleries[2].update!(gallery_groups: [group])
    char = create(:character, user: user, galleries: galleries, default_icon: icons.first, name: 'Test char')

    login(user)

    visit character_path(char)

    within('.character-info-box') do
      click_link 'Galleries'
    end

    def minimize_gallery(current_headers, index)
      within(current_headers[index]) do
        aggregate_failures do
          expect(page).to have_link('-')
          expect(page).to have_no_link('+')
        end

        click_link '-'

        aggregate_failures do
          expect(page).to have_no_link('-')
          expect(page).to have_link('+')
        end
      end
    end

    def maximize_gallery(current_headers, index)
      within(current_headers[index]) do
        aggregate_failures do
          expect(page).to have_no_link('-')
          expect(page).to have_link('+')
        end

        click_link '+'

        aggregate_failures do
          expect(page).to have_link('-')
          expect(page).to have_no_link('+')
        end
      end
    end

    def current_headers
      all('.gallery-header')
    end

    def current_titles
      all('.gallery-title').map(&:text)
    end

    within('.character-right-content-box') do
      aggregate_failures do
        expect(current_titles).to eq(["Gallery 0", "Gallery 1", "Gallery 2", "Gallery 3"])
        expect(page).to have_selector('.gallery-icons', count: 4)
        expect(page).to have_selector(".gallery-data-#{galleries.first.id}")
      end

      minimize_gallery(current_headers, 0)

      aggregate_failures do
        expect(page).to have_selector('.gallery-icons', count: 3)
        expect(page).to have_no_selector(".gallery-data-#{galleries.first.id}")
      end

      maximize_gallery(current_headers, 0)

      aggregate_failures do
        expect(page).to have_selector('.gallery-icons', count: 4)
        expect(page).to have_selector(".gallery-data-#{galleries.first.id}")
        expect(page).to have_selector(".gallery-data-#{galleries[2].id}")
      end

      minimize_gallery(current_headers, 2)

      aggregate_failures do
        expect(page).to have_selector('.gallery-icons', count: 3)
        expect(page).to have_no_selector(".gallery-data-#{galleries[2].id}")

        # arrow pressing
        within(current_headers.first) do
          expect(page).to have_selector('.section-up.disabled-arrow')
          expect(page).to have_selector('.section-down.pointer')
        end

        within(current_headers.last) do
          expect(page).to have_selector('.section-up.pointer')
          expect(page).to have_selector('.section-down.disabled-arrow')
        end
      end

      def gallery_title_for(id)
        find(".gallery-title-#{id}", visible: :all)
      end

      def gallery_data_for(id)
        find(".gallery-data-#{id}", visible: :all)
      end

      def expect_tbody_order(order, galleries)
        aggregate_failures do
          expect(current_titles).to eq(order.map { |x| "Gallery #{x}" })
          # convert orders to gallery IDs to the relevant .gallery-title-n and .gallery-data-n tbodies
          expected_tbody_order = order.map { |name| galleries[name].id }.map { |id| [gallery_title_for(id), gallery_data_for(id)] }.flatten
          # then make sure the page tbodies are in this order
          expect(all('tbody', visible: :all).to_a).to eq(expected_tbody_order)
        end
      end

      # clicking the up button on the first gallery should do nothing
      within(current_headers.first) do
        click_link 'Move Up'
      end

      expect_tbody_order([0, 1, 2, 3], galleries)

      # move the first gallery down (testing boundaries)
      within(current_headers.first) do
        click_link 'Move Down'
      end

      aggregate_failures do
        expect(current_titles).to eq(["Gallery 1", "Gallery 0", "Gallery 2", "Gallery 3"])
        expect_tbody_order([1, 0, 2, 3], galleries)

        # make sure arrows got re-disabled correctly
        within(current_headers.first) do
          expect(page).to have_selector('.section-up.disabled-arrow')
          expect(page).to have_selector('.section-down.pointer')
        end
        within(current_headers[1]) do
          expect(page).to have_selector('.section-up.pointer')
          expect(page).to have_selector('.section-down.pointer')
        end
      end

      # move it down again (testing non-boundaries)
      within(current_headers[1]) do
        click_link 'Move Down'
      end

      aggregate_failures do
        expect(current_titles).to eq(["Gallery 1", "Gallery 2", "Gallery 0", "Gallery 3"])
        expect_tbody_order([1, 2, 0, 3], galleries)
      end

      # test moving up
      within(current_headers[1]) do
        click_link 'Move Up'
      end

      aggregate_failures do
        expect(current_titles).to eq(["Gallery 2", "Gallery 1", "Gallery 0", "Gallery 3"])
        expect_tbody_order([2, 1, 0, 3], galleries)
      end
    end

    # reload page and ensure the ordering is correct (ensure it persisted)
    visit current_url

    within('.character-right-content-box') do
      expect(current_titles).to eq(["Gallery 2", "Gallery 1", "Gallery 0", "Gallery 3"])
    end
  end
end
