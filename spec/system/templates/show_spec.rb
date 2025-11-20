RSpec.describe "Viewing a template" do
  let!(:user) { create(:user) }
  let!(:template) { create(:template, user: user, name: 'sample template') }

  let!(:earth) { create(:setting, name: 'Earth') }
  let!(:icon) { create(:icon, user: user, url: 'https://example.org/sample.png') }
  let!(:post_character) { create(:character, user: user, template: template) }
  let!(:post) { create(:post, user: user, character: post_character, subject: 'Template post') }
  let!(:characters) do
    data = [
      { name: 'Test character' },
      { name: 'Nicknamed', nickname: 'Other name' },
      { name: 'Character with screenname', screenname: 'test-screenname' },
      { name: 'Played by', pb: 'Test Person' },
      { name: 'With setting', settings: [earth] },
      { name: 'Iconned', default_icon: icon },
    ]
    [post_character] +
      data.map { |d| create(:character, d.merge(user: user, template: template)) }
  end

  before(:each) do
    create(:template, user: user, name: 'Unrelated template')
    create(:character, user: user, name: 'Unrelated character')
    create(:post, user: user, subject: 'Unrelated post')
  end

  scenario "Viewing in list mode", :aggregate_failures do
    visit template_path(template, view: 'list')
    expect(page).to have_text('Template: sample template')
    expect(page).to have_no_text('Unrelated template')

    # check characters
    within table_titled('Template: sample template') do
      characters.each do |character|
        row = find('tr', text: character.name)
        within(row) do
          expect(page).to have_link(character.name, href: character_path(character))
          [:nickname, :screenname, :pb].each do |param|
            val = character.public_send(param)
            expect(page).to have_text(val) if val.present?
          end
          character.settings.each do |setting|
            expect(page).to have_link(setting.name, href: tag_path(setting))
          end
        end
      end

      expect(page).to have_no_text('Unrelated character')
    end

    # check posts
    within table_titled('Posts with Template Instances') do
      expect(page).to have_link('Template post', href: post_path(post))
      expect(page).to have_no_text('Unrelated post')
    end
  end

  scenario "Viewing in icon mode", :aggregate_failures do
    visit template_path(template, view: 'icons')
    expect(page).to have_text('Template: sample template')
    expect(page).to have_no_text('Unrelated template')

    # check characters
    within table_titled('Template: sample template') do
      characters.each do |character|
        within('.character-icon-item', text: character.name) do
          expect(page).to have_link(character.name, href: character_path(character))
          next unless (default_icon = character.default_icon).present?

          icon = find('img')
          expect(icon[:src]).to eq(default_icon.url)
          expect(icon[:title]).to eq(default_icon.keyword)
          expect(icon[:alt]).to eq(default_icon.keyword)
        end
      end

      expect(page).to have_no_text('Unrelated character')
    end

    # check posts
    within table_titled('Posts with Template Instances') do
      expect(page).to have_link('Template post', href: post_path(post))
      expect(page).to have_no_text('Unrelated post')
    end
  end
end
