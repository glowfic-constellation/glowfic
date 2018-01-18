require "spec_helper"

RSpec.describe CharactersGallery do
  it "should reset section_order fields in other galleries after deletion" do
    character = create(:character)
    gallery = create(:gallery, user: character.user)
    cg0 = CharactersGallery.create(character: character, gallery: gallery)
    expect(cg0.section_order).to eq(0)
    gallery = create(:gallery, user: character.user)
    cg1 = CharactersGallery.create(character: character, gallery: gallery)
    expect(cg1.section_order).to eq(1)
    gallery = create(:gallery, user: character.user)
    cg2 = CharactersGallery.create(character: character, gallery: gallery)
    expect(cg2.section_order).to eq(2)

    cg1.destroy!

    expect(cg0.reload.section_order).to eq(0)
    expect(cg2.reload.section_order).to eq(1)
  end

  it "should autofill gallery order" do
    character = create(:character)
    gallery = create(:gallery, user: character.user)
    cg = CharactersGallery.create(character: character, gallery: gallery)
    expect(cg.section_order).to eq(0)
    gallery = create(:gallery, user: character.user)
    cg = CharactersGallery.create(character: character, gallery: gallery)
    expect(cg.section_order).to eq(1)
    gallery = create(:gallery, user: character.user)
    cg = CharactersGallery.create(character: character, gallery: gallery)
    expect(cg.section_order).to eq(2)
  end
end
