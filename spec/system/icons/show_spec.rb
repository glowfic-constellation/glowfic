RSpec.describe "Viewing an icon" do
  let(:user) { create(:user, username: 'Jane Doe', password: 'known') }
  let(:icon) { create(:icon, user: user, keyword: 'iconic') }
  let(:gallery) { create(:gallery, user: user, name: 'Example Gallery')}

  scenario "Viewing a galleryless icon" do
    visit icon_path(icon)

    expect(page).to have_selector('.breadcrumbs', text: 'Jane Doe » Jane Doe\'s Galleries » (0 Galleries) » iconic » Stats')

    within('.icon-info-box') do
      expect(page).to have_selector('.icon-keyword', text: 'iconic')
      expect(page.find('.icon')['src']).to eq(icon.url)
      expect(page).to have_link('Stats')
      expect(page).to have_link('Galleries')
      expect(page).to have_link('Posts')
      expect(page).to have_link('Replies')
      expect(page).not_to have_link('Edit Icon')
      expect(page).not_to have_link('Make Avatar')
      expect(page).not_to have_link('Replace Icon')
      expect(page).not_to have_link('Delete Icon')
    end

    within('.icon-right-content-box') do
      expect(page).to have_selector('th', text: 'Times Used')
      within(row_for('Times Used')) do
        expect(page).to have_selector('td', text: '0')
      end

      expect(page).to have_selector('th', text: 'Posts In')
      within(row_for('Posts In')) do
        expect(page).to have_selector('td', text: '0')
      end
    end

    within('.icon-info-box') do
      click_link 'Galleries'
    end

    within('.icon-right-content-box') do
      expect(page).to have_text('— No galleries yet —')
    end

    within('.icon-info-box') do
      click_link 'Posts'
    end

    within('.icon-right-content-box') do
      expect(page).to have_text('— No posts yet —')
    end
  end

  scenario "Viewing own icon" do
    login(user, 'known')
    visit icon_path(icon)

    expect(page).to have_selector('.breadcrumbs', text: 'Galleries » (0 Galleries) » iconic » Stats')

    within('.icon-info-box') do
      expect(page).to have_selector('.icon-keyword', text: 'iconic')
      expect(page.find('.icon')['src']).to eq(icon.url)
      expect(page).to have_link('Stats')
      expect(page).to have_link('Galleries')
      expect(page).to have_link('Posts')
      expect(page).to have_link('Replies')
      expect(page).to have_link('Edit Icon')
      expect(page).to have_link('Make Avatar')
      expect(page).to have_link('Replace Icon')
      expect(page).to have_link('Delete Icon')
    end

    within('.icon-right-content-box') do
      expect(page).to have_selector('th', text: 'Times Used')
      within(row_for('Times Used')) do
        expect(page).to have_selector('td', text: '0')
      end

      expect(page).to have_selector('th', text: 'Posts In')
      within(row_for('Posts In')) do
        expect(page).to have_selector('td', text: '0')
      end
    end
  end

  scenario "Viewing an icon with a gallery" do
    login
    gallery.update!(icons: [icon])
    visit icon_path(icon)

    expect(page).to have_selector('.breadcrumbs', text: 'Jane Doe » Jane Doe\'s Galleries » Example Gallery » iconic » Stats')

    within('.icon-info-box') do
      expect(page).to have_selector('.icon-keyword', text: 'iconic')
      expect(page.find('.icon')['src']).to eq(icon.url)
      expect(page).to have_link('Stats')
      expect(page).to have_link('Galleries')
      expect(page).to have_link('Posts')
      expect(page).to have_link('Replies')
      expect(page).not_to have_link('Edit Icon')
      expect(page).not_to have_link('Make Avatar')
      expect(page).not_to have_link('Replace Icon')
      expect(page).not_to have_link('Delete Icon')
    end

    within('.icon-right-content-box') do
      expect(page).to have_selector('th', text: 'Times Used')
      within(row_for('Times Used')) do
        expect(page).to have_selector('td', text: '0')
      end

      expect(page).to have_selector('th', text: 'Posts In')
      within(row_for('Posts In')) do
        expect(page).to have_selector('td', text: '0')
      end
    end

    within('.icon-info-box') do
      click_link 'Galleries'
    end

    within('.icon-right-content-box') do
      expect(page).to have_selector('.gallery-title', count: 1)
      expect(page).to have_link(text: 'Example Gallery', href: gallery_path(gallery))
    end
  end

  scenario "Viewing a complex icon" do
    gallery.update!(icons: [icon])
    icon2 = create(:icon, user: user)
    g2 = create(:gallery, user: user, name: 'Second Gallery', icons: [icon, icon2])

    post = create(:post, user: user, icon: icon, subject: "Example Post")
    create(:reply, post: post)
    create(:reply, post: post, user: user, icon: icon)
    rpost = create(:post, subject: "Example Reply Post")
    create(:reply, user: user, icon: icon, post: rpost)

    visit icon_path(icon)

    expect(page).to have_selector('.breadcrumbs', text: 'Jane Doe » Jane Doe\'s Galleries » Example Gallery » iconic » Stats')

    within('.icon-info-box') do
      expect(page).to have_selector('.icon-keyword', text: 'iconic')
      expect(page.find('.icon')['src']).to eq(icon.url)
      expect(page).to have_link('Stats')
      expect(page).to have_link('Galleries')
      expect(page).to have_link('Posts')
      expect(page).to have_link('Replies')
      expect(page).not_to have_link('Edit Icon')
      expect(page).not_to have_link('Make Avatar')
      expect(page).not_to have_link('Replace Icon')
      expect(page).not_to have_link('Delete Icon')
    end

    within('.icon-right-content-box') do
      expect(page).to have_selector('th', text: 'Times Used')
      within(row_for('Times Used')) do
        expect(page).to have_selector('td', text: '3')
      end

      expect(page).to have_selector('th', text: 'Posts In')
      within(row_for('Posts In')) do
        expect(page).to have_selector('td', text: '2')
      end
    end

    within('.icon-info-box') do
      click_link 'Galleries'
    end

    within('.icon-right-content-box') do
      expect(page).to have_selector('.gallery-title', count: 2)
      expect(page).to have_link('Example Gallery', href: gallery_path(gallery))
      expect(page).to have_link('Second Gallery', href: gallery_path(g2))

      within("#gallery#{g2.id}") do
        expect(page).to have_selector('.gallery-icon', count: 2)
        expect(page).to have_link(href: icon_path(icon))
        expect(page).to have_link(href: icon_path(icon2))
      end
    end

    within('.icon-info-box') do
      click_link 'Posts'
    end

    within('.icon-right-content-box') do
      expect(page).to have_link('Example Post', href: post_path(post))
      expect(page).to have_link('Example Reply Post', href: post_path(rpost))
    end
  end
end
