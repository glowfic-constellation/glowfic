RSpec.describe CharactersGallery do
  it "should reset section_order fields in other galleries after deletion" do
    character = create(:character)
    gallery = create(:gallery, user: character.user)
    cg0 = CharactersGallery.create!(character: character, gallery: gallery)
    expect(cg0.section_order).to eq(0)
    gallery = create(:gallery, user: character.user)
    cg1 = CharactersGallery.create!(character: character, gallery: gallery)
    expect(cg1.section_order).to eq(1)
    gallery = create(:gallery, user: character.user)
    cg2 = CharactersGallery.create!(character: character, gallery: gallery)
    expect(cg2.section_order).to eq(2)

    cg1.destroy!

    expect(cg0.reload.section_order).to eq(0)
    expect(cg2.reload.section_order).to eq(1)
  end

  it "should autofill gallery order" do
    character = create(:character)
    gallery = create(:gallery, user: character.user)
    cg = CharactersGallery.create!(character: character, gallery: gallery)
    expect(cg.section_order).to eq(0)
    gallery = create(:gallery, user: character.user)
    cg = CharactersGallery.create!(character: character, gallery: gallery)
    expect(cg.section_order).to eq(1)
    gallery = create(:gallery, user: character.user)
    cg = CharactersGallery.create!(character: character, gallery: gallery)
    expect(cg.section_order).to eq(2)
  end

  it "should prevent duplicate joins for the same character and gallery" do
    character = create(:character)
    gallery = create(:gallery, user: character.user)
    character.galleries << gallery
    cg = character.characters_galleries.create(gallery: gallery)
    expect(cg.persisted?).to be(false)
    expect(cg).not_to be_valid
    expect(cg.errors.messages).to eq({ character: ['has already been taken'] })
  end

  it "should allow multiple galleries on the same character" do
    character = create(:character)
    character.galleries << create(:gallery, user: character.user)
    gallery2 = create(:gallery, user: character.user)
    cg = character.characters_galleries.create(gallery: gallery2)
    expect(cg.persisted?).to be(true)
    expect(cg).to be_valid
  end

  it "should allow multiple characters to have the same gallery" do
    character = create(:character)
    gallery = create(:gallery, user: character.user)
    character.galleries << gallery
    character2 = create(:character, user: character.user)
    cg = character2.characters_galleries.create(gallery: gallery)
    expect(cg.persisted?).to be(true)
    expect(cg).to be_valid
  end
end
