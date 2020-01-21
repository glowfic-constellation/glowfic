require "spec_helper"

RSpec.feature "Listing characters", type: :feature do
  def with_template(characters, template)
    {
      template: template,
      characters: characters.map do |d|
        create(:character, d.merge(user: template.user, template: template))
      end,
    }
  end

  def without_template(characters)
    {
      characters: characters.map { |d| create(:character, d.merge(user: user)) },
    }
  end

  let!(:user) { create(:user, username: 'Sample user') }
  let!(:templates) {
    data = [
      { name: 'template 1' },
      { name: 'template 2' },
    ]
    data.map { |d| create(:template, d.merge(user: user)) }
  }

  let!(:earth) { create(:setting, name: 'Earth') }
  let!(:icon) { create(:icon, user: user, url: 'https://example.org/sample.png') }

  let!(:character_data) do
    [
      with_template([
        { name: 'Test character' },
        { name: 'Nicknamed', template_name: 'Other name' },
        { name: 'Character with screenname', screenname: 'test-screenname' },
        { name: 'Played by', pb: 'Test Person' },
        { name: 'With setting', settings: [earth] },
        { name: 'Iconned', default_icon: icon },
      ], templates.first),
      with_template([
        { name: 'Second template character' },
      ], templates.last),
      without_template([
        { name: 'Untemplated character' },
      ]),
    ]
  end

  before(:each) do
    create(:template, name: 'Unrelated template') # unrelated template
    create(:character, name: 'Unrelated character') # unrelated character
  end

  def expect_character_rows(characters)
    characters.each do |character|
      row = find('tr', text: character.name)
      within(row) do
        expect(page).to have_link(character.name, href: character_path(character))
        [:template_name, :screenname, :pb].each do |param|
          val = character.public_send(param)
          expect(page).to have_text(val) if val.present?
        end
        character.settings.each do |setting|
          expect(page).to have_link(setting.name, href: tag_path(setting))
        end
      end
    end
  end

  scenario "Viewing in list mode, separated by template" do
    visit user_characters_path(user_id: user.id, view: 'list', character_split: 'template')
    expect(page).to have_text("Sample user's Characters")

    expect(page).not_to have_text('Unrelated template')
    expect(page).not_to have_text('Unrelated character')

    character_data.each do |data|
      text = if data[:template]
        'Template: ' + data[:template].name
      else
        'No Template'
      end
      expect(page).to have_selector('tr', text: text)

      expect_character_rows(data[:characters])
    end
  end

  scenario "Viewing in list mode, unseparated" do
    visit user_characters_path(user_id: user.id, view: 'list', character_split: 'none')
    expect(page).to have_text("Sample user's Characters")

    expect(page).not_to have_text('Unrelated template')
    expect(page).not_to have_text('Unrelated character')

    expect(page).not_to have_text('Template:')

    character_data.each do |data|
      expect_character_rows(data[:characters])
    end
  end

  def expect_character_icons(characters)
    characters.each do |character|
      link = find_link(character.name, href: character_path(character))
      within(link) do
        expect(page).to have_text(character.screenname) if character.screenname.present?
        icon = character.default_icon
        next unless icon.present?

        img = find('img')
        expect(img[:src]).to eq(icon.url)
        expect(img[:alt]).to eq(icon.keyword)
        expect(img[:title]).to eq(icon.keyword)
      end
    end
  end

  scenario "Viewing in icon mode, separated by template" do
    visit user_characters_path(user_id: user.id, view: 'icon', character_split: 'template')
    expect(page).to have_text("Sample user's Characters")

    expect(page).not_to have_text('Unrelated template')
    expect(page).not_to have_text('Unrelated character')

    character_data.each do |data|
      text = if data[:template]
        'Template: ' + data[:template].name
      else
        'No Template'
      end
      expect(page).to have_selector('tr', text: text)

      expect_character_icons(data[:characters])
    end
  end

  scenario "Viewing in icon mode, unseparated" do
    visit user_characters_path(user_id: user.id, view: 'icon', character_split: 'none')
    expect(page).to have_text("Sample user's Characters")

    expect(page).not_to have_text('Unrelated template')
    expect(page).not_to have_text('Unrelated character')

    expect(page).not_to have_text('Template:')

    character_data.each do |data|
      expect_character_icons(data[:characters])
    end
  end
end
