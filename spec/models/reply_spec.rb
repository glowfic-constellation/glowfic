require "spec_helper"

RSpec.describe Reply do
  describe "view cache" do
    before(:each) do
      @reply = create(:reply, with_icon: true, with_character: true)
      @key = @reply.send(:view_cache_key)
      Rails.cache.write(@key, 'test')
    end

    it "should expire when the reply is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.content = 'something new'
      @reply.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should expire when the reply is destroyed" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.destroy
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should expire when the character is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.character.name = 'something new'
      @reply.character.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should only expire when relevant character fields are updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.character.template = create(:template)
      @reply.character.save
      expect(Rails.cache.read(@key)).to eq('test')
    end

    it "should expire when the icon is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.icon.keyword = 'something new'
      @reply.icon.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should only expire when relevant icon fields are updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.icon.has_gallery = !@reply.icon.has_gallery
      @reply.icon.save
      expect(Rails.cache.read(@key)).to eq('test')
    end

    it "should expire when the user is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.user.username = 'something new'
      @reply.user.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should only expire when relevant user fields are updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.user.moiety = 'something new'
      @reply.user.save
      expect(Rails.cache.read(@key)).to eq('test')
    end
  end

  describe "#has_icons?" do
    let(:user) { create(:user) }

    context "without character" do
      let(:reply) { create(:reply, user: user) }

      it "is true with avatar" do
        icon = create(:icon, user: user)
        user.update_attributes(avatar: icon)
        user.reload

        expect(reply.character).to be_nil
        expect(reply.has_icons?).to be_true
      end

      it "is false without avatar" do
        expect(reply.character).to be_nil
        expect(reply.has_icons?).not_to be_true
      end
    end

    context "with character" do
      let(:character) { create(:character, user: user) }
      let(:reply) { create(:reply, user: user, character: character) }

      it "is true with default icon" do
        icon = create(:icon, user: user)
        character.update_attributes(default_icon: icon)
        expect(reply.has_icons?).to be_true
      end

      it "is false without galleries" do
        expect(reply.has_icons?).not_to be_true
      end

      it "is true with icons in galleries" do
        gallery = create(:gallery, user: user)
        gallery.icons << create(:icon, user: user)
        character.galleries << gallery
        expect(reply.has_icons?).to be_true
      end

      it "is false without icons in galleries" do
        character.galleries << create(:gallery, user: user)
        expect(reply.has_icons?).not_to be_true
      end
    end
  end
end
