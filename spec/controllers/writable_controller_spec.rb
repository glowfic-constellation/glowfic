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
end
