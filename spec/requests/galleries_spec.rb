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

  describe '#show' do
    let(:user) { create(:user) }
    let(:gallery) { create(:gallery, user: user) }
    let(:body) { response.parsed_body }

    before(:each) { create_list(:icon, 10, galleries: [gallery], user: user) }

    context 'with icon view'
    context 'with list view' do
      it 'works' do
        get "/galleries/#{gallery.id}?view=list"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('_single')
          expect(response).to render_template('_list_section')
          expect(response).to render_template('_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          breadcrumbs = [user.username, "#{user.username}'s Galleries", gallery.name]
          expect(text_clean(body.at_css('.flash.breadcrumbs'))).to eq(breadcrumbs.join(' » '))

          title = [gallery.name, 'Icons', 'List'].join(' ')
          expect(text_clean(body.at_css('.gallery-table-title'))).to eq(title)

          expect(body.css("#gallery#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-title-#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-data-#{gallery.id}")).not_to be_empty

          gallery.icons.ordered.each_with_index do |icon, i|
            expect(body.css('.icon-keyword')[i].text.strip).to eq(icon.keyword)
          end
        end
      end

      it 'works for gallery user' do
        login(user)

        get "/galleries/#{gallery.id}?view=list"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('_single')
          expect(response).to render_template('_list_section')
          expect(response).to render_template('_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to eq("You are now logged in as #{user.username}. Welcome back!")

          breadcrumbs = ['You', 'Your Galleries', gallery.name]
          expect(text_clean(body.at_css('.flash.breadcrumbs'))).to eq(breadcrumbs.join(' » '))

          title = [gallery.name, '+ Add Icons', 'Edit Gallery', 'x Delete Gallery', 'Icons', 'List'].join(' ')
          expect(text_clean(body.at_css('.gallery-table-title'))).to eq(title)

          expect(body.css("#gallery#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-title-#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-data-#{gallery.id}")).not_to be_empty

          gallery.icons.ordered.each_with_index do |icon, i|
            expect(body.css('.icon-keyword')[i].text.strip).to eq(icon.keyword)
          end

          expect(body.at_css('.form-table-ender input[name=gallery_delete]')[:value]).to eq('- Remove selected icons from gallery')
          expect(body.at_css('.form-table-ender input[name=commit]')[:value]).to eq('x Delete selected icons permanently')
        end
      end

      it 'works for galleryless' do
        create_list(:icon, 10, user: user)
        login(user)

        get "/galleries/0?view=list"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('_single')
          expect(response).to render_template('_list_section')
          expect(response).to render_template('_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to eq("You are now logged in as #{user.username}. Welcome back!")

          breadcrumbs = ['You', 'Your Galleries', 'Galleryless Icons']
          expect(text_clean(body.at_css('.flash.breadcrumbs'))).to eq(breadcrumbs.join(' » '))

          title = ['Galleryless icons', '+ Add Icons', 'Icons', 'List'].join(' ')
          expect(text_clean(body.at_css('.gallery-table-title'))).to eq(title)

          subheader = 'Unsorted icons without a gallery will appear here. They can still be individually assigned to a character with no galleries.'
          expect(body.at_css('.gallery-subheader .sub').text).to eq(subheader)

          expect(body.css('#gallery0')).not_to be_empty

          user.galleryless_icons.ordered.each_with_index do |icon, i|
            expect(body.css('.icon-keyword')[i].text.strip).to eq(icon.keyword)
          end

          expect(body.css('.form-table-ender input[name=gallery_delete]')).to be_empty
          expect(body.at_css('.form-table-ender input[name=commit]')[:value]).to eq('x Delete selected icons permanently')
        end
      end

      it 'works with many icons' do
        create_list(:icon, 100, user: user, galleries: [gallery]) # rubocop:disable Factorybot/ExcessiveCreateList

        get "/galleries/#{gallery.id}?view=list"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('_single')
          expect(response).to render_template('_list_section')
          expect(response).to render_template('_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          title = [gallery.name, 'Icons', 'List'].join(' ')
          expect(text_clean(body.at_css('.gallery-table-title'))).to eq(title)

          expect(body.css("#gallery#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-title-#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-data-#{gallery.id}")).not_to be_empty

          gallery.icons.ordered[0..99].each_with_index do |icon, i|
            expect(body.css('.icon-keyword')[i].text.strip).to eq(icon.keyword)
          end

          expect(text_clean(body.at_css('.paginator'))).to eq('Total: 110 ‹ Previous 1 2 Next › « First ‹ Previous 1 of 2 Next › Last »')
        end
      end

      it 'works with no icons' do
        gallery.icons.destroy_all

        get "/galleries/#{gallery.id}?view=list"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('_single')
          expect(response).not_to render_template('_list_section')
          expect(response).not_to render_template('_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          breadcrumbs = [user.username, "#{user.username}'s Galleries", gallery.name]
          expect(text_clean(body.at_css('.flash.breadcrumbs'))).to eq(breadcrumbs.join(' » '))

          title = [gallery.name, 'Icons', 'List'].join(' ')
          expect(text_clean(body.at_css('.gallery-table-title'))).to eq(title)

          expect(body.css("#gallery#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-title-#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-data-#{gallery.id}")).not_to be_empty

          expect(body.css('.icon-keyword')).to be_empty

          expect(body.at_css('.no-icons').text).to eq('— No icons yet —')
        end
      end

      it 'works with gallery groups' do
        groups = create_list(:gallery_group, 3).each { |g| g.update!(galleries: [gallery]) }

        get "/galleries/#{gallery.id}?view=list"

        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response).to render_template(:show)
          expect(response).to render_template('_single')
          expect(response).to render_template('_list_section')
          expect(response).to render_template('_list_item')

          expect(flash[:error]).to be_nil
          expect(flash[:success]).to be_nil

          breadcrumbs = [user.username, "#{user.username}'s Galleries", gallery.name]
          expect(text_clean(body.at_css('.flash.breadcrumbs'))).to eq(breadcrumbs.join(' » '))

          title = [gallery.name, 'Icons', 'List'].join(' ')
          expect(text_clean(body.at_css('.gallery-table-title'))).to eq(title)

          expect(body.css("#gallery#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-title-#{gallery.id}")).not_to be_empty
          expect(body.css(".gallery-data-#{gallery.id}")).not_to be_empty

          tags = ['Groups:'] + groups.map(&:name)
          expect(text_clean(body.at_css("#gallery-tags-#{gallery.id}"))).to eq(tags.join(' '))

          gallery.icons.ordered.each_with_index do |icon, i|
            expect(body.css('.icon-keyword')[i].text.strip).to eq(icon.keyword)
          end
        end
      end
    end
  end
end
