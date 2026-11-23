RSpec.describe "Gallery" do
  describe "search" do
    it "works" do
      get "/galleries/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
      end

      # TODO: perform a search when this is no longer under construction
    end
  end

  describe "update" do
    # The edit form posts every icon in the gallery as nested attributes and
    # relies on Rack::MethodOverride to turn the POST into a PUT. With Rack's
    # stock cap of 4096 form parameters, a gallery of a few hundred icons
    # overflowed the cap, the override was silently skipped, and the POST hit
    # no route: a 404 on rename. Mirror the browser exactly, `_method` and all.
    it "renames a gallery large enough to overflow Rack's stock parameter cap" do
      user = login
      gallery = create(:gallery, user: user, name: 'Old Name')
      icons = create_list(:icon, 520, user: user) # rubocop:disable FactoryBot/ExcessiveCreateList
      # rubocop:disable-next Rails/SkipsModelValidations
      GalleriesIcon.insert_all(icons.map { |icon| { gallery_id: gallery.id, icon_id: icon.id } })

      icon_params = gallery.galleries_icons.includes(:icon).to_h do |gi|
        [
          gi.id.to_s,
          {
            id: gi.id,
            _destroy: '0',
            icon_attributes: {
              id: gi.icon.id,
              url: gi.icon.url,
              s3_key: '',
              keyword: gi.icon.keyword,
              credit: '',
              _destroy: '0',
            },
          },
        ]
      end

      post "/galleries/#{gallery.id}", params: {
        _method: 'put',
        gallery: { name: 'New Name', galleries_icons_attributes: icon_params },
      }

      aggregate_failures do
        expect(response).to redirect_to(edit_gallery_url(gallery))
        expect(flash[:success]).to eq('Gallery updated.')
        expect(gallery.reload.name).to eq('New Name')
        expect(gallery.icons.count).to eq(520)
      end
    end
  end
end
