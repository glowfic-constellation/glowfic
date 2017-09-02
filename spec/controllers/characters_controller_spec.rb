require "spec_helper"

RSpec.describe CharactersController do
  describe "GET index" do
    it "requires login without an id" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid id" do
      get :index, user_id: -1
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "succeeds with an id" do
      user = create(:user)
      get :index, user_id: user.id
      expect(response.status).to eq(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end

    it "succeeds with an id when logged in" do
      user = create(:user)
      login
      get :index, user_id: user.id
      expect(response.status).to eq(200)
    end

    it "does something with character groups" do
      skip "Character groups need to be refactored"
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views
      it "sets correct variables" do
        user = create(:user)
        templates = Array.new(2) { create(:template, user: user) }
        names = ['— Create New Template —'] + templates.map(&:name)
        create(:template)

        login_as(user)
        get :new

        expect(assigns(:page_title)).to eq("New Character")
        expect(assigns(:templates).map(&:name)).to match_array(names)
        expect(controller.gon.character_id).to eq('')
        expect(controller.gon.user_id).to eq(user.id)
        expect(controller.gon.gallery_groups).to eq([])
        expect(assigns(:aliases)).to be_blank
      end
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with missing params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "fails with invalid params" do
      login
      post :create, character: {}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "succeeds when valid" do
      expect(Character.count).to eq(0)
      test_name = 'Test character'
      user = create(:user)
      template = create(:template, user: user)
      gallery = create(:gallery, user: user)

      login_as(user)
      post :create, character: {name: test_name, template_name: 'TempName', screenname: 'just-a-test', setting: 'A World', template_id: template.id, pb: 'Facecast', description: 'Desc', ungrouped_gallery_ids: [gallery.id]}

      expect(response).to redirect_to(assigns(:character))
      expect(flash[:success]).to eq("Character saved successfully.")
      expect(Character.count).to eq(1)
      character = assigns(:character).reload
      expect(character.name).to eq(test_name)
      expect(character.user_id).to eq(user.id)
      expect(character.template_name).to eq('TempName')
      expect(character.screenname).to eq('just-a-test')
      expect(character.setting).to eq('A World')
      expect(character.template).to eq(template)
      expect(character.pb).to eq('Facecast')
      expect(character.description).to eq('Desc')
      expect(character.galleries).to match_array([gallery])
    end

    it "creates new templates when specified" do
      expect(Template.count).to eq(0)
      login
      post :create, character: {template_id: 0, new_template_name: 'TemplateTest', name: 'Test'}
      expect(Template.count).to eq(1)
      expect(Template.first.name).to eq('TemplateTest')
      expect(assigns(:character).template_id).to eq(Template.first.id)
    end

    context "with views" do
      render_views
      it "sets correct variables when invalid" do
        user = create(:user)
        gallery = create(:gallery, user: user)
        group = create(:gallery_group)
        group_gallery = create(:gallery, user: user, gallery_groups: [group])
        templates = Array.new(2) { create(:template, user: user) }
        names = ['— Create New Template —'] + templates.map(&:name)
        create(:template)

        login_as(user)
        post :create, character: {ungrouped_gallery_ids: [gallery.id, group_gallery.id], gallery_group_ids: [group.id]}

        expect(response).to render_template(:new)
        expect(controller.gon.character_id).to eq('')
        expect(assigns(:templates).map(&:name)).to match_array(names)
        expect(assigns(:character).ungrouped_gallery_ids).to match_array([gallery.id, group_gallery.id])
        expect(assigns(:character).gallery_group_ids).to eq([group.id])
      end
    end
  end

  describe "GET show" do
    it "requires valid character" do
      get :show, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "should succeed when logged out" do
      character = create(:character)
      get :show, id: character.id
      expect(response.status).to eq(200)
    end

    it "should succeed when logged in" do
      character = create(:character)
      login
      get :show, id: character.id
      expect(response.status).to eq(200)
    end

    it "should set correct variables" do
      character = create(:character)
      Array.new(26) { create(:post, character: character, user: character.user) }
      get :show, id: character.id
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq(character.name)
      expect(assigns(:posts).size).to eq(25)
      expect(assigns(:posts)).to match_array(Post.where(character_id: character.id).order('tagged_at desc').limit(25))
    end

    it "should only show visible posts" do
      character = create(:character)
      create(:post, character: character, user: character.user, privacy: Post::PRIVACY_PRIVATE)
      get :show, id: character.id
      expect(assigns(:posts)).to be_blank
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character id" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires character with permissions" do
      login
      get :edit, id: create(:character).id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "succeeds when logged in" do
      character = create(:character)
      login_as(character.user)
      get :edit, id: character.id
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views
      it "sets correct variables" do
        user = create(:user)
        group = create(:gallery_group)
        gallery = create(:gallery, user: user, gallery_groups: [group])
        character = create(:character, user: user, gallery_groups: [group])
        calias = create(:alias, character: character)
        templates = Array.new(2) { create(:template, user: user) }
        names = ['— Create New Template —'] + templates.map(&:name)
        create(:template)

        login_as(user)
        get :edit, id: character.id

        expect(assigns(:page_title)).to eq("Edit Character: #{character.name}")
        expect(controller.gon.character_id).to eq(character.id)
        expect(controller.gon.user_id).to eq(user.id)
        expect(controller.gon.gallery_groups.map{|g|g[:id]}).to eq([group.id])
        expect(controller.gon.gallery_groups.map{|g|g[:gallery_ids]}).to eq([[gallery.id]])
        expect(assigns(:gallery_groups)).to match_array([group])
        expect(assigns(:templates).map(&:name)).to match_array(names)
        expect(assigns(:aliases)).to match_array([calias])
      end
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character id" do
      login
      put :update, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires character with permissions" do
      login
      put :update, id: create(:character).id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "fails with invalid params" do
      character = create(:character)
      login_as(character.user)
      put :update, id: character.id, character: {name: ''}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "fails with invalid template params" do
      character = create(:character)
      login_as(character.user)
      new_name = character.name + 'aaa'
      put :update, id: character.id, character: {template_id: 0, new_template_name: '', name: new_name}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
      expect(character.reload.name).not_to eq(new_name)
    end

    it "succeeds when valid" do
      character = create(:character)
      user = character.user
      login_as(user)
      new_name = character.name + 'aaa'
      template = create(:template, user: user)
      gallery = create(:gallery, user: user)
      put :update, id: character.id, character: {name: new_name, template_name: 'TemplateName', screenname: 'a-new-test', setting: 'Another World', template_id: template.id, pb: 'Actor', description: 'Description', ungrouped_gallery_ids: [gallery.id]}

      expect(response).to redirect_to(assigns(:character))
      expect(flash[:success]).to eq("Character saved successfully.")
      character.reload
      expect(character.name).to eq(new_name)
      expect(character.template_name).to eq('TemplateName')
      expect(character.screenname).to eq('a-new-test')
      expect(character.setting).to eq('Another World')
      expect(character.template).to eq(template)
      expect(character.pb).to eq('Actor')
      expect(character.description).to eq('Description')
      expect(character.galleries).to match_array([gallery])
    end

    it "adds galleries by groups" do
      user = create(:user)
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group], user: user)
      character = create(:character, user: user)
      login_as(user)
      put :update, id: character.id, character: {gallery_group_ids: [group.id]}

      expect(flash[:success]).to eq('Character saved successfully.')
      character.reload
      expect(character.gallery_groups).to match_array([group])
      expect(character.galleries).to match_array([gallery])
      expect(character.ungrouped_gallery_ids).to be_blank
      expect(character.characters_galleries.first).to be_added_by_group
    end

    it "removes gallery only if not shared between groups" do
      user = create(:user)
      group1 = create(:gallery_group) # gallery1
      group2 = create(:gallery_group) # -> gallery1
      group3 = create(:gallery_group) # gallery2 ->
      group4 = create(:gallery_group) # gallery2
      gallery1 = create(:gallery, gallery_groups: [group1, group2], user: user)
      gallery2 = create(:gallery, gallery_groups: [group3, group4], user: user)
      character = create(:character, gallery_groups: [group1, group3, group4], user: user)
      login_as(user)
      put :update, id: character.id, character: {gallery_group_ids: [group2.id, group4.id]}

      expect(flash[:success]).to eq('Character saved successfully.')
      character.reload
      expect(character.gallery_groups).to match_array([group2, group4])
      expect(character.galleries).to match_array([gallery1, gallery2])
      expect(character.ungrouped_gallery_ids).to be_blank
      expect(character.characters_galleries.map(&:added_by_group)).to eq([true, true])
    end

    it "does not remove gallery if tethered by group" do
      user = create(:user)
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group], user: user)
      character = create(:character, gallery_groups: [group], user: user)
      character.ungrouped_gallery_ids = [gallery.id]
      character.save!
      expect(character.characters_galleries.first).not_to be_added_by_group

      login_as(user)
      put :update, id: character.id, character: {ungrouped_gallery_ids: []}
      expect(flash[:success]).to eq('Character saved successfully.')
      character.reload
      expect(character.gallery_groups).to match_array([group])
      expect(character.galleries).to match_array([gallery])
      expect(character.ungrouped_gallery_ids).to be_blank
      expect(character.characters_galleries.first).to be_added_by_group
    end

    it "works when adding both group and gallery" do
      user = create(:user)
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group], user: user)
      character = create(:character, user: user)

      login_as(user)
      put :update, id: character.id, character: {gallery_group_ids: [group.id], ungrouped_gallery_ids: [gallery.id]}
      expect(flash[:success]).to eq('Character saved successfully.')
      character.reload
      expect(character.gallery_groups).to match_array([group])
      expect(character.galleries).to match_array([gallery])
      expect(character.ungrouped_gallery_ids).to eq([gallery.id])
      expect(character.characters_galleries.first).not_to be_added_by_group
    end

    it "does not add another user's galleries" do
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group])
      character = create(:character)

      login_as(character.user)
      put :update, id: character.id, character: {gallery_group_ids: [group.id]}
      expect(flash[:success]).to eq('Character saved successfully.')
      character.reload
      expect(character.gallery_groups).to match_array([group])
      expect(character.galleries).to be_blank
    end

    it "removes untethered galleries when group goes" do
      user = create(:user)
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group], user: user)
      character = create(:character, gallery_groups: [group], user: user)

      login_as(user)
      put :update, id: character.id, character: {gallery_group_ids: []}
      expect(flash[:success]).to eq('Character saved successfully.')
      character.reload
      expect(character.gallery_groups).to eq([])
      expect(character.galleries).to eq([])
    end

    it "creates new templates when specified" do
      expect(Template.count).to eq(0)
      character = create(:character)
      login_as(character.user)
      put :update, id: character.id, character: {template_id: 0, new_template_name: 'Test'}
      expect(Template.count).to eq(1)
      expect(Template.first.name).to eq('Test')
      expect(character.reload.template_id).to eq(Template.first.id)
    end

    context "with views" do
      render_views
      it "sets correct variables when invalid" do
        user = create(:user)
        group = create(:gallery_group)
        gallery = create(:gallery, user: user, gallery_groups: [group])
        character = create(:character, user: user, gallery_groups: [group])
        templates = Array.new(2) { create(:template, user: user) }
        names = ['— Create New Template —'] + templates.map(&:name)
        create(:template)

        login_as(user)
        put :update, id: character.id, character: {name: ''}

        expect(response).to render_template(:edit)
        expect(controller.gon.character_id).to eq(character.id)
        expect(controller.gon.user_id).to eq(user.id)
        expect(controller.gon.gallery_groups.map{|g|g[:id]}).to eq([group.id])
        expect(controller.gon.gallery_groups.map{|g|g[:gallery_ids]}).to eq([[gallery.id]])
        expect(assigns(:gallery_groups)).to match_array([group])
        expect(assigns(:templates).map(&:name)).to match_array(names)
      end
    end

    it "reorders galleries as necessary" do
      character = create(:character)
      g1 = create(:gallery, user: character.user)
      g2 = create(:gallery, user: character.user)
      character.galleries << g1
      character.galleries << g2
      g1_cg = CharactersGallery.where(gallery_id: g1.id).first
      g2_cg = CharactersGallery.where(gallery_id: g2.id).first
      expect(g1_cg.section_order).to eq(0)
      expect(g2_cg.section_order).to eq(1)

      login_as(character.user)
      put :update, id: character.id, character: {ungrouped_gallery_ids: [g2.id.to_s]}

      expect(character.reload.galleries.pluck(:id)).to eq([g2.id])
      expect(g2_cg.reload.section_order).to eq(0)
    end
  end

  describe "GET facecasts" do
    it "does not require login" do
      get :facecasts
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("Facecasts")
    end

    it "sets correct variables for facecast name sort" do
      chars = Array.new(3) { create(:character, pb: SecureRandom.urlsafe_base64) }
      get :facecasts
      expect(assigns(:pbs).keys).to match_array(chars.map(&:pb))
    end

    it "sets correct variables for character name sort: character only" do
      chars = Array.new(3) { create(:character, pb: SecureRandom.urlsafe_base64) }
      get :facecasts, sort: 'name'
      expect(assigns(:pbs).keys).to match_array(chars)
    end

    it "sets correct variables for character name sort: template only" do
      chars = Array.new(3) { create(:template_character, pb: SecureRandom.urlsafe_base64) }
      get :facecasts, sort: 'name'
      expect(assigns(:pbs).keys).to match_array(chars.map(&:template))
    end

    it "sets correct variables for character name sort: character and template mixed" do
      chars = Array.new(3) { create(:template_character, pb: SecureRandom.urlsafe_base64) }
      chars += Array.new(3) { create(:character, pb: SecureRandom.urlsafe_base64) }
      get :facecasts, sort: 'name'
      expect(assigns(:pbs).keys).to match_array(chars.map { |c| c.template || c })
    end

    it "sets correct variables for writer sort" do
      chars = Array.new(3) { create(:template_character, pb: SecureRandom.urlsafe_base64) }
      chars += Array.new(3) { create(:character, pb: SecureRandom.urlsafe_base64) }
      get :facecasts, sort: 'writer'
      expect(assigns(:pbs).keys).to match_array(chars.map(&:user))
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires permission" do
      user = create(:user)
      login_as(user)
      character = create(:character)
      expect(character.user_id).not_to eq(user.id)
      delete :destroy, id: character.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "succeeds" do
      character = create(:character)
      login_as(character.user)
      delete :destroy, id: character.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:success]).to eq("Character deleted successfully.")
      expect(Character.find_by_id(character.id)).to be_nil
    end
  end

  describe "GET replace" do
    it "requires login" do
      character = create(:character)
      get :replace, id: character.id
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq('You must be logged in to view that page.')
    end

    it "requires valid character" do
      login
      get :replace, id: -1
      expect(response).to redirect_to(characters_path)
      expect(flash[:error]).to eq('Character could not be found.')
    end

    it "requires own character" do
      character = create(:character)
      login
      get :replace, id: character.id
      expect(response).to redirect_to(characters_path)
      expect(flash[:error]).to eq('You do not have permission to edit that character.')
    end

    it "sets correct variables" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      other_char.default_icon = create(:icon, user: user)
      other_char.save
      calias = create(:alias, character: other_char)
      char_post = create(:post, user: user, character: character)
      create(:reply, user: user, post: char_post, character: character) # reply
      create(:post) # other post
      char_reply2 = create(:reply, user: user, character: character) # other reply

      login_as(user)
      get :replace, id: character.id
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Replace Character: ' + character.name)

      expect(controller.gon.gallery[other_char.id][:url]).to eq(other_char.default_icon.url)
      expect(controller.gon.gallery[other_char.id][:aliases]).to eq([calias.as_json])
      expect(assigns(:posts)).to match_array([char_post, char_reply2.post])
    end

    context "with template" do
      it "sets alts correctly" do
        user = create(:user)
        template = create(:template, user: user)
        character = create(:character, user: user, template: template)
        alts = Array.new(5) { create(:character, user: user, template: template) }
        create(:character, user: user) # other character

        login_as(user)
        get :replace, id: character.id
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Replace Character: ' + character.name)
        expect(assigns(:alts)).to match_array(alts)
        expect(assigns(:alt_dropdown).length).to eq(alts.length)
      end

      it "includes character if no others in template" do
        user = create(:user)
        template = create(:template, user: user)
        character = create(:character, user: user, template: template)
        create(:character, user: user) # other character

        login_as(user)
        get :replace, id: character.id
        expect(response).to have_http_status(200)
        expect(assigns(:alts)).to match_array([character])
      end
    end

    context "without template" do
      it "sets alts correctly" do
        user = create(:user)
        character = create(:character, user: user)
        alts = Array.new(5) { create(:character, user: user) }
        template = create(:template, user: user)
        create(:character, user: user, template: template) # other character

        login_as(user)
        get :replace, id: character.id
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Replace Character: ' + character.name)
        expect(assigns(:alts)).to match_array(alts)
        expect(assigns(:alt_dropdown).length).to eq(alts.length)
      end

      it "includes character if no others in template" do
        user = create(:user)
        template = create(:template, user: user)
        character = create(:character, user: user)
        create(:character, user: user, template: template) # other character

        login_as(user)
        get :replace, id: character.id
        expect(response).to have_http_status(200)
        expect(assigns(:alts)).to match_array([character])
      end
    end
  end

  describe "POST do_replace" do
    it "requires login" do
      character = create(:character)
      post :do_replace, id: character.id
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq('You must be logged in to view that page.')
    end

    it "requires valid character" do
      login
      post :do_replace, id: -1
      expect(response).to redirect_to(characters_path)
      expect(flash[:error]).to eq('Character could not be found.')
    end

    it "requires own character" do
      character = create(:character)
      login
      post :do_replace, id: character.id
      expect(response).to redirect_to(characters_path)
      expect(flash[:error]).to eq('You do not have permission to edit that character.')
    end

    it "requires valid other character" do
      character = create(:character)
      login_as(character.user)
      post :do_replace, id: character.id, icon_dropdown: -1
      expect(response).to redirect_to(replace_character_path(character))
      expect(flash[:error]).to eq('Character could not be found.')
    end

    it "requires other character to be yours if present" do
      character = create(:character)
      other_char = create(:character)
      login_as(character.user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id
      expect(response).to redirect_to(replace_character_path(character))
      expect(flash[:error]).to eq('That is not your character.')
    end

    it "requires valid new alias if parameter provided" do
      character = create(:character)
      login_as(character.user)
      post :do_replace, id: character.id, alias_dropdown: -1
      expect(response).to redirect_to(replace_character_path(character))
      expect(flash[:error]).to eq('Invalid new alias.')
    end

    it "requires matching new alias if parameter provided" do
      character = create(:character)
      other_char = create(:character, user: character.user)
      calias = create(:alias)
      login_as(character.user)
      post :do_replace, id: character.id, alias_dropdown: calias.id, icon_dropdown: other_char.id
      expect(response).to redirect_to(replace_character_path(character))
      expect(flash[:error]).to eq('Invalid new alias.')
    end

    it "requires valid old alias if parameter provided" do
      character = create(:character)
      login_as(character.user)
      post :do_replace, id: character.id, orig_alias: -1
      expect(response).to redirect_to(replace_character_path(character))
      expect(flash[:error]).to eq('Invalid old alias.')
    end

    it "requires matching old alias if parameter provided" do
      character = create(:character)
      calias = create(:alias)
      login_as(character.user)
      post :do_replace, id: character.id, orig_alias: calias.id
      expect(response).to redirect_to(replace_character_path(character))
      expect(flash[:error]).to eq('Invalid old alias.')
    end

    it "succeeds with valid other character" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      char_post = create(:post, user: user, character: character)
      reply = create(:reply, user: user, character: character)
      reply_post_char = reply.post.character_id

      login_as(user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id
      expect(response).to redirect_to(character_path(character))
      expect(flash[:success]).to eq('All uses of this character have been replaced.')

      expect(char_post.reload.character_id).to eq(other_char.id)
      expect(reply.reload.character_id).to eq(other_char.id)
      expect(reply.post.reload.character_id).to eq(reply_post_char) # check it doesn't replace all replies in a post
    end

    it "succeeds with no other character" do
      user = create(:user)
      character = create(:character, user: user)
      char_post = create(:post, user: user, character: character)
      reply = create(:reply, user: user, character: character)

      login_as(user)
      post :do_replace, id: character.id
      expect(response).to redirect_to(character_path(character))
      expect(flash[:success]).to eq('All uses of this character have been replaced.')

      expect(char_post.reload.character_id).to be_nil
      expect(reply.reload.character_id).to be_nil
    end

    it "succeeds with alias" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      calias = create(:alias, character: other_char)
      char_post = create(:post, user: user, character: character)
      reply = create(:reply, user: user, character: character)

      login_as(user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id, alias_dropdown: calias.id

      expect(char_post.reload.character_id).to eq(other_char.id)
      expect(reply.reload.character_id).to eq(other_char.id)
      expect(char_post.reload.character_alias_id).to eq(calias.id)
      expect(reply.reload.character_alias_id).to eq(calias.id)
    end

    it "filters to selected posts if given" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      char_post = create(:post, user: user, character: character)
      char_reply = create(:reply, user: user, character: character)
      other_post = create(:post, user: user, character: character)

      login_as(user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id, post_ids: [char_post.id, char_reply.post.id]
      expect(response).to redirect_to(character_path(character))
      expect(flash[:success]).to eq('All uses of this character have been replaced.')

      expect(char_post.reload.character_id).to eq(other_char.id)
      expect(char_reply.reload.character_id).to eq(other_char.id)
      expect(other_post.reload.character_id).to eq(character.id)
    end

    it "filters to alias if given" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      calias = create(:alias, character: character)
      char_post = create(:post, user: user, character: character)
      char_reply = create(:reply, user: user, character: character, character_alias_id: calias.id)

      login_as(user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id, orig_alias: calias.id

      expect(char_post.reload.character_id).to eq(character.id)
      expect(char_reply.reload.character_id).to eq(other_char.id)
    end

    it "filters to nil if given" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      calias = create(:alias, character: character)
      char_post = create(:post, user: user, character: character)
      char_reply = create(:reply, user: user, character: character, character_alias_id: calias.id)

      login_as(user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id, orig_alias: ''

      expect(char_post.reload.character_id).to eq(other_char.id)
      expect(char_reply.reload.character_id).to eq(character.id)
    end

    it "does not filter if all given" do
      user = create(:user)
      character = create(:character, user: user)
      other_char = create(:character, user: user)
      calias = create(:alias, character: character)
      char_post = create(:post, user: user, character: character)
      char_reply = create(:reply, user: user, character: character, character_alias_id: calias.id)

      login_as(user)
      post :do_replace, id: character.id, icon_dropdown: other_char.id, orig_alias: 'all'

      expect(char_post.reload.character_id).to eq(other_char.id)
      expect(char_reply.reload.character_id).to eq(other_char.id)
    end
  end

  describe "GET search" do
    it 'works logged in' do
      login
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:users)).to be_empty
      expect(assigns(:templates)).to be_empty
    end

    it 'works logged out' do
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:users)).to be_empty
    end

    it 'searches author' do
      author = create(:user)
      found = create(:character, user: author)
      notfound = create(:character, user: create(:user))
      get :search, commit: true, author_id: author.id
      expect(response).to have_http_status(200)
      expect(assigns(:users)).to match_array([author])
      expect(assigns(:search_results)).to match_array([found])
    end

    it "sets templates by author" do
      author = create(:user)
      template = create(:template, user: author)
      create(:template)
      get :search, commit: true, author_id: author.id
      expect(assigns(:templates)).to eq([template])
    end

    it 'searches template' do
      author = create(:user)
      template = create(:template, user: author)
      found = create(:character, user: author, template: template)
      notfound = create(:character, user: author, template: create(:template, user: author))
      get :search, commit: true, template_id: template.id
      expect(response).to have_http_status(200)
      expect(assigns(:templates)).to match_array([template])
      expect(assigns(:search_results)).to match_array([found])
    end

    context "searching" do
      before(:each) do
        @name = create(:character, name: 'a', screenname: 'b', template_name: 'c')
        @nickname = create(:character, name: 'b', screenname: 'c', template_name: 'a')
        @screenname = create(:character, name: 'c', screenname: 'a', template_name: 'b')
      end

      it "searches names correctly" do
        get :search, commit: true, name: 'a', search_name: true
        expect(assigns(:search_results)).to match_array([@name])
      end

      it "searches screenname correctly" do
        get :search, commit: true, name: 'a', search_screenname: true
        expect(assigns(:search_results)).to match_array([@screenname])
      end

      it "searches nickname correctly" do
        get :search, commit: true, name: 'a', search_nickname: true
        expect(assigns(:search_results)).to match_array([@nickname])
      end

      it "searches name + screenname correctly" do
        get :search, commit: true, name: 'a', search_name: true, search_screenname: true
        expect(assigns(:search_results)).to match_array([@name, @screenname])
      end

      it "searches name + nickname correctly" do
        get :search, commit: true, name: 'a', search_name: true, search_nickname: true
        expect(assigns(:search_results)).to match_array([@name, @nickname])
      end

      it "searches nickname + screenname correctly" do
        get :search, commit: true, name: 'a', search_nickname: true, search_screenname: true
        expect(assigns(:search_results)).to match_array([@nickname, @screenname])
      end

      it "searches all correctly" do
        get :search, commit: true, name: 'a', search_name: true, search_screenname: true, search_nickname: true
        expect(assigns(:search_results)).to match_array([@name, @screenname, @nickname])
      end
    end
  end

  describe "POST duplicate" do
    it "requires login" do
      post :duplicate, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq('You must be logged in to view that page.')
    end

    it "requires valid character id" do
      login
      post :duplicate, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq('Character could not be found.')
    end

    it "requires character with permissions" do
      login
      post :duplicate, id: create(:character).id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq('You do not have permission to edit that character.')
    end

    it "succeeds" do
      user = create(:user)
      template = create(:template, user: user)
      icon = create(:icon, user: user)
      gallery = create(:gallery, icons: [icon], user: user)
      group = create(:gallery_group)
      gallery2 = create(:gallery, gallery_groups: [group], user: user)
      gallery3 = create(:gallery, gallery_groups: [group], user: user)
      character = create(:character, template: template, galleries: [gallery, gallery2], gallery_groups: [group], default_icon: icon, user: user)
      calias = create(:alias, character: character)
      char_post = create(:post, character: character, user: user)
      char_reply = create(:reply, character: character, user: user)

      character.reload

      expect(character.galleries).to match_array([gallery, gallery2, gallery3])
      expect(character.ungrouped_gallery_ids).to match_array([gallery.id, gallery2.id])
      expect(character.gallery_groups).to match_array([group])

      login_as(user)
      expect do
        post :duplicate, id: character.id
      end.to not_change {
        [Template.count, Gallery.count, Icon.count, Reply.count, Post.count, Tag.count]
      }.and change { Character.count }.by(1).and change { CharactersGallery.count }.by(3).and change { CharacterTag.count }.by(1)

      dup = assigns(:dup)
      dup.reload
      character.reload
      expect(response).to redirect_to(edit_character_url(dup))
      expect(flash[:success]).to eq('Character duplicated successfully. You are now editing the new character.')

      expect(dup).not_to eq(character)

      # check all attrs but id, created_at and updated_at are same
      dup_attrs = dup.attributes.clone
      char_attrs = character.attributes.clone
      ['id', 'created_at', 'updated_at'].each do |val|
        dup_attrs.delete(val)
        char_attrs.delete(val)
      end
      expect(dup_attrs).to eq(char_attrs)

      # check character associations aren't changed
      expect(character.template).to eq(template)
      expect(character.galleries).to match_array([gallery, gallery2, gallery3])
      expect(character.ungrouped_gallery_ids).to match_array([gallery.id, gallery2.id])
      expect(character.gallery_groups).to match_array([group])
      expect(character.default_icon).to eq(icon)
      expect(character.user).to eq(user)
      expect(character.aliases.map(&:name)).to eq([calias.name])

      # check duplicate has appropriate associations
      expect(dup.template).to eq(template)
      expect(dup.galleries).to match_array([gallery, gallery2, gallery3])
      expect(dup.ungrouped_gallery_ids).to match_array([gallery.id, gallery2.id])
      expect(dup.gallery_groups).to match_array([group])
      expect(dup.default_icon).to eq(icon)
      expect(dup.user).to eq(user)
      expect(dup.aliases.map(&:name)).to eq([calias.name])

      # check old posts and replies have old attributes
      char_post.reload
      char_reply.reload
      expect(char_post.character).to eq(character)
      expect(char_reply.character).to eq(character)
    end
  end
end
