RSpec.describe IconHelper do
  describe "#icon_tag" do
    it "requires an icon" do
      expect(helper.icon_tag(nil)).to eq('')
    end

    it "delegates to icon_mem_tag" do
      icon = create(:icon)
      allow(helper).to receive(:icon_mem_tag).and_call_original
      expect(helper).to receive(:icon_mem_tag).with(icon.url, icon.keyword)
      helper.icon_tag(icon)
    end
  end

  describe "#icon_mem_tag" do
    let(:icon) { create(:icon) }
    let(:url) { icon.url }
    let(:keyword) { icon.keyword }

    it "requires a url" do
      expect(helper.icon_mem_tag(nil, 'foo')).to eq('')
    end

    it "returns the correct image_tag" do
      expect(helper.icon_mem_tag(url, keyword)).to eq_structured_html([
        { tag: "img", path: "/html/body/img", attrs: { src: url, alt: keyword, title: keyword, class: IconHelper::ICON } },
      ])
    end

    it "takes a parameter for pointers" do
      expect(helper.icon_mem_tag(url, keyword, pointer: true)).to eq_structured_html([
        { tag: "img", path: "/html/body/img", attrs: { src: url, alt: keyword, title: keyword, class: IconHelper::ICON + ' pointer' } },
      ])
    end

    it "takes a parameter for a class" do
      klass = 'vmid preview_icon'
      expect(helper.icon_mem_tag(url, keyword, class: klass)).to eq_structured_html([
        { tag: "img", path: "/html/body/img", attrs: { src: url, alt: keyword, title: keyword, class: IconHelper::ICON + ' ' + klass } },
      ])
    end
  end

  describe "#dropdown_icons" do
    let(:user) { create(:user) }
    let(:post) { build(:post, user: user) }
    let(:character) { create(:character, user: user) }

    before(:each) do
      without_partial_double_verification do
        allow(helper).to receive(:current_user).and_return(user)
      end
    end

    it "returns an empty string with no icons" do
      create_list(:icon, 3, user: user)
      expect(helper.dropdown_icons(post)).to eq('')
    end

    it "returns avatar with no character" do
      avatar = create(:icon)
      user.update!(avatar: avatar)
      html = select_tag :icon_dropdown, options_for_select([[avatar.keyword, avatar.id]], avatar.id), prompt: "No Icon"
      expect(helper.dropdown_icons(post)).to eq(html)
    end

    it "returns icons collection if galleries" do
      icons = ['icon 1', 'icon 2', 'icon 3'].map { |k| create(:icon, keyword: k, user: user) }
      character.galleries << create(:gallery, user: user, icons: icons[0..1])
      character.galleries << create(:gallery, user: user, icons: [icons.last])
      icons = Icon.where(id: icons.map(&:id))
      post.character = character
      html = select_tag :icon_dropdown, options_for_select(icons.ordered.map { |i| [i.keyword, i.id] }, nil), prompt: "No Icon"
      expect(helper.dropdown_icons(post, character.galleries)).to eq(html)
    end

    it "returns icons if character has icons" do
      icons = ['icon 1', 'icon 2', 'icon 3'].map { |k| create(:icon, keyword: k, user: user) }
      character.galleries << create(:gallery, icons: icons)
      post.character = character
      post.icon = icons[0]
      icons = Icon.where(id: icons.map(&:id)).ordered
      html = select_tag :icon_dropdown, options_for_select(icons.map { |i| [i.keyword, i.id] }, post.icon_id), prompt: "No Icon"
      expect(helper.dropdown_icons(post)).to eq(html)
    end

    it "returns default icon if character only has that" do
      icon = create(:icon, user: user)
      character.update!(default_icon: icon)
      post.character = character
      html = select_tag :icon_dropdown, options_for_select([[icon.keyword, icon.id]], nil), prompt: "No Icon"
      expect(helper.dropdown_icons(post)).to eq(html)
    end

    it "returns icon if post icon" do
      icon = create(:icon, user: user)
      post.character = character
      post.icon = icon
      html = select_tag :icon_dropdown, options_for_select([[icon.keyword, icon.id]], icon.id), prompt: "No Icon"
      expect(helper.dropdown_icons(post)).to eq(html)
    end
  end
end
