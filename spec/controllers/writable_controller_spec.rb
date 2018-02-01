require 'spec_helper'

RSpec.describe WritableController do
  describe "#setup_layout_gon" do
    it "does not error when logged out" do
      controller.send(:setup_layout_gon)
    end

    it "works when logged in with default theme" do
      login
      controller.send(:setup_layout_gon)
      expect(controller.gon.editor_class).to be_nil
      expect(controller.gon.base_url).not_to be_nil
    end

    context "with dark theme" do
      ['dark', 'starrydark'].each do |theme|
        it "works with theme '#{theme}'" do
          user = create(:user, layout: theme)
          login_as(user)
          controller.send(:setup_layout_gon)
          expect(controller.gon.editor_class).to eq('layout_' + theme)
          expect(controller.gon.base_url).not_to be_nil
          expect(controller.gon.tinymce_css_path).not_to be_nil
        end
      end
    end
  end

  describe "#og_data_for_post" do
    it "succeeds" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', board: board, user: user)

      data = controller.send(:og_data_for_post, post, 1, 5, 25)
      expect(data).to eq({
        title: 'Temp · Test',
        description: '(Tester – page 1 of 5)'
      })
    end

    it "works with description" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', description: 'More.', board: board, user: user)

      data = controller.send(:og_data_for_post, post, 1, 5, 25)
      expect(data).to eq({
        title: 'Temp · Test',
        description: 'More. (Tester – page 1 of 5)'
      })
    end

    it "strips tags from description" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', description: 'With an <a href="/characters/1">Alli</a>.', board: board, user: user)

      data = controller.send(:og_data_for_post, post, 1, 5, 25)
      expect(data).to eq({
        title: 'Temp · Test',
        description: 'With an Alli. (Tester – page 1 of 5)'
      })
    end

    it "works with section" do
      board = create(:board, name: 'Test')
      section = create(:board_section, board: board, name: 'Further')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', description: 'More.', board: board, section: section, user: user)

      data = controller.send(:og_data_for_post, post, 1, 5, 25)
      expect(data).to eq({
        title: 'Temp · Test » Further',
        description: 'More. (Tester – page 1 of 5)'
      })
    end

    it "works with two authors" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      user2 = create(:user, username: 'Friend')
      post = create(:post, subject: 'Temp', description: 'More.', board: board, user: user)
      create(:reply, post: post, user: user2)

      data = controller.send(:og_data_for_post, post, 1, 5, 25)
      expect(data).to eq({
        title: 'Temp · Test',
        description: 'More. (Friend, Tester – page 1 of 5)'
      })
    end

    it "works with pages that are not the first" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', board: board, user: user)

      data = controller.send(:og_data_for_post, post, 2, 2, 25)
      expect(data).to eq({
        title: 'Temp · Test',
        description: '(Tester – page 2 of 2)'
      })
    end

    it "works with many authors" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', board: board, user: user)
      5.times do |i|
        user2 = create(:user, username: "Friend #{i}")
        create(:reply, post: post, user: user2)
      end

      data = controller.send(:og_data_for_post, Post.find_by(id: post.id), 1, 5, 25)
      expect(data).to eq({
        title: 'Temp · Test',
        description: '(Tester and 5 others – page 1 of 5)'
      })
    end

    it "works with non-standard per_page" do
      board = create(:board, name: 'Test')
      user = create(:user, username: 'Tester')
      post = create(:post, subject: 'Temp', board: board, user: user)

      data = controller.send(:og_data_for_post, post, 1, 5, 5)
      expect(data).to eq({
        title: 'Temp · Test',
        description: '(Tester – page 1 of 5, 5/page)'
      })
    end
  end
end
