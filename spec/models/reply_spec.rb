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
end
