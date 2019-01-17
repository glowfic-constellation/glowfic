require "spec_helper"

RSpec.shared_examples "gallery" do |method|
  let(:user) { create(:user) }
  let(:gallery) {
    if method == 'update!'
      create(:gallery, user: user)
    else
      build(:gallery, user: user)
    end
  }
  let(:params) { ActionController::Parameters.new({ id: gallery.id }) }

  it "requires valid params" do
    params[:gallery] = {name: ''}
    saver = Gallery::Saver.new(gallery, user: user, params: params)
    expect { saver.send(method) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "successfully updates" do
    group = create(:gallery_group)
    params[:gallery] = {name: 'NewGalleryName', gallery_group_ids: [group.id]}

    saver = Gallery::Saver.new(gallery, user: user, params: params)
    expect { saver.send(method) }.not_to raise_error

    gallery.reload
    expect(gallery.name).to eq('NewGalleryName')
    expect(gallery.gallery_groups).to match_array([group])
  end

  it "creates new gallery groups" do
    existing_name = create(:gallery_group)
    existing_case = create(:gallery_group)
    tags = ['_atag', '_atag', create(:gallery_group).id, '', '_' + existing_name.name, '_' + existing_case.name.upcase]

    params[:gallery] = {gallery_group_ids: tags}

    saver = Gallery::Saver.new(gallery, user: user, params: params)
    expect { saver.send(method) }.to change{GalleryGroup.count}.by(1)

    expect(GalleryGroup.last.name).to eq('atag')
    expect(gallery.reload.gallery_groups.count).to eq(4)
  end

  it "orders gallery groups" do
    group3 = create(:gallery_group, user: user)
    group1 = create(:gallery_group, user: user)
    group2 = create(:gallery_group, user: user)
    params[:gallery] = { gallery_group_ids: [group1, group2, group3].map(&:id) }

    saver = Gallery::Saver.new(gallery, user: user, params: params)
    expect { saver.send(method) }.not_to raise_error

    expect(gallery.gallery_groups).to eq([group1, group2, group3])
  end
end

RSpec.describe Gallery::Saver do
  describe "create" do
    it_behaves_like "gallery", 'create!'
  end

  describe "update" do
    it_behaves_like "gallery", 'update!'

    let(:user) { create(:user) }
    let(:gallery) { create(:gallery, user: user) }
    let(:params) { ActionController::Parameters.new({ id: gallery.id }) }

    it "can remove a gallery icon from the gallery" do
      icon = create(:icon, user: user)
      gallery.icons << icon
      expect(icon.reload.has_gallery).to eq(true)

      icon_attributes = {id: icon.id}
      gid = gallery.galleries_icons.first.id
      gallery_icon_attributes = {id: gid, _destroy: '1', icon_attributes: icon_attributes}

      params[:gallery] = {galleries_icons_attributes: {gid.to_s => gallery_icon_attributes}}

      saver = Gallery::Saver.new(gallery, user: user, params: params)
      expect { saver.update! }.not_to raise_error

      expect(gallery.reload.icons).to be_empty
      expect(icon.reload).not_to be_nil
      expect(icon.has_gallery).not_to eq(true)
    end

    it "can delete a gallery icon" do
      icon = create(:icon, user: user)
      gallery.icons << icon

      icon_attributes = {id: icon.id, _destroy: '1'}
      gid = gallery.galleries_icons.first.id
      gallery_icon_attributes = {id: gid, icon_attributes: icon_attributes}

      params[:gallery] = {galleries_icons_attributes: {gid.to_s => gallery_icon_attributes}}

      saver = Gallery::Saver.new(gallery, user: user, params: params)
      expect { saver.update! }.not_to raise_error

      expect(gallery.reload.icons).to be_empty
      expect(Icon.find_by_id(icon.id)).to be_nil
    end

    it "can update a gallery icon" do
      icon = create(:icon, user: user)
      newkey = icon.keyword + 'new'
      gallery.icons << icon

      icon_attributes = {id: icon.id, keyword: newkey}
      gid = gallery.galleries_icons.first.id
      gallery_icon_attributes = {id: gid, icon_attributes: icon_attributes}

      params[:gallery] = {galleries_icons_attributes: {gid.to_s => gallery_icon_attributes}}

      saver = Gallery::Saver.new(gallery, user: user, params: params)
      expect { saver.update! }.not_to raise_error

      expect(icon.reload.keyword).to eq(newkey)
    end
  end
end
