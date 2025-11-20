RSpec.describe "Show a list of galleries", :aggregate_failures do
  let(:user) { create(:user, username: 'Test user') }

  before(:each) do
    create(:icon, user: user, keyword: "galleryless <strong> icon")
    create(:gallery, user: user, name: 'Empty gallery')

    icon1 = create(:icon, user: user, keyword: "galleryful <strong> icon")
    create(:gallery, user: user, name: 'Gallery1', icons: [icon1])

    icon2 = create(:icon, user: user)
    group1 = create(:gallery_group, name: 'Test group B')
    group2 = create(:gallery_group, name: 'Test group A')
    group3 = create(:gallery_group, name: 'Test group C')
    create(:gallery, user: user, name: 'Gallery2', icons: [icon2], gallery_groups: [group1, group3, group2])
  end

  def expect_gallery_of(name, size, tags=[])
    aggregate_failures do
      gallery_row = find('tr') { |x| x.has_selector?('.gallery-name a', exact_text: name) }
      within(gallery_row) do
        expect(page).to have_selector('.gallery-icon-count', exact_text: size.to_s)
        if tags.empty?
          expect(page).to have_no_selector('.tag-box .tag-item-link')
        else
          seen_tags = all('.tag-box .tag-item-link').map(&:text)
          expect(seen_tags).to eq(tags)
        end
      end
    end
  end

  def gallery_row_for(name)
    find('tr') { |x| x.has_selector?('.gallery-name', exact_text: name) }
  end

  scenario "View a user's list of galleries while logged out" do
    visit user_galleries_path(user_id: user.id)

    expect(page).to have_selector('th', text: "Test user's Galleries")
    expect(page).to have_no_selector('.gallery-new')

    within('#content tbody') do
      expect(page).to have_no_selector('.gallery-add')
      expect(page).to have_no_selector('.gallery-edit')
      expect(page).to have_no_selector('.gallery-delete')

      expect_gallery_of('[Galleryless]', 1)
      expect_gallery_of('Empty gallery', 0)
      expect_gallery_of('Gallery1', 1)
      expect_gallery_of('Gallery2', 1, ['Test group B', 'Test group C', 'Test group A'])
    end
  end

  scenario "Expanding a user's list of galleries while logged out", :js do
    visit user_galleries_path(user_id: user.id)

    within('#content tbody') do
      expect(page).to have_no_text('galleryless <strong> icon')
      within(gallery_row_for('[Galleryless]')) { find('.gallery-box').click }
      expect(page).to have_text('galleryless <strong> icon')

      expect(page).to have_no_text("galleryful <strong> icon")
      within(gallery_row_for('Gallery1')) { find('.gallery-box').click }
      expect(page).to have_text('galleryful <strong> icon')
    end
  end

  scenario "View another user's list of galleries while logged in" do
    login
    visit user_galleries_path(user_id: user.id)

    expect(page).to have_selector('th', text: "Test user's Galleries")
    expect(page).to have_no_selector('.gallery-new')

    within('#content tbody') do
      expect(page).to have_no_selector('.gallery-add')
      expect(page).to have_no_selector('.gallery-edit')
      expect(page).to have_no_selector('.gallery-delete')

      expect_gallery_of('[Galleryless]', 1)
      expect_gallery_of('Empty gallery', 0)
      expect_gallery_of('Gallery1', 1)
      expect_gallery_of('Gallery2', 1, ['Test group B', 'Test group C', 'Test group A'])
    end
  end

  scenario "View own list of galleries" do
    login(user)
    visit user_galleries_path(user_id: user.id)

    expect(page).to have_selector('.gallery-table-title', text: "Your Galleries")
    expect(page).to have_selector('.gallery-new')

    within('#content tbody') do
      expect(page).to have_selector('.gallery-add', count: 4)
      expect(page).to have_selector('.gallery-edit', count: 3)
      expect(page).to have_selector('.gallery-delete', count: 3)
      expect_gallery_of('[Galleryless]', 1)
      expect_gallery_of('Empty gallery', 0)
      expect_gallery_of('Gallery1', 1)
      expect_gallery_of('Gallery2', 1, ['Test group B', 'Test group C', 'Test group A'])
    end
  end
end
