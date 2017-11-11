RSpec.shared_examples "taggable" do |type, klass|
  let(:model_name) { described_class.name.underscore }
  let(:taggable) { create(model_name) }
  it "creates new #{type} tags if they don't exist" do
    taggable.send(type + '_ids=', ['_tag'])
    expect(taggable.send(type + 's').map(&:name)).to match_array(['tag'])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's')
    tag_ids = taggable.send(type + '_ids')
    expect(tags.map(&:name)).to match_array(['tag'])
    expect(tags.map(&:user)).to match_array([taggable.user])
  end

  it "uses extant tags with same name and type for #{type}" do
    tag = create(klass || type)
    old_user = tag.user
    taggable.send(type + '_ids=', ['_' + tag.name])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's')
    expect(tags).to match_array([tag])
    expect(tags.map(&:user)).to match_array([old_user])
  end

  it "does not use extant tags of a different type with same name for #{type}" do
    name = "Example Tag"
    tag = create(:tag, type: 'NonexistentTag', name: name)
    taggable.send(type + '_ids=', ['_' + name])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's')
    tag_ids = taggable.send(type + '_ids')
    expect(tags.map(&:name)).to match_array([name])
    expect(tags.map(&:user)).to match_array([taggable.user])
    expect(tags).not_to include(tag)
    expect(tag_ids).to match_array(tags.map(&:id))
  end

  it "uses extant #{type} tags by id" do
    tag = create(klass || type)
    old_user = tag.user
    taggable.send(type + '_ids=', [tag.id.to_s])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's')
    tag_ids = taggable.send(type + '_ids')
    expect(tags).to match_array([tag])
    expect(tags.map(&:user)).to match_array([old_user])
    expect(tag_ids).to match_array([tag.id])
  end

  it "removes #{type} tags when not in list given" do
    tag = create(klass || type)
    taggable.send(type + 's=', [tag])
    taggable.save
    taggable.reload
    expect(taggable.send(type + 's')).to match_array([tag])
    taggable.send(type + '_ids=', [])
    taggable.save
    taggable.reload
    expect(taggable.send(type + 's')).to eq([])
    expect(taggable.send(type + '_ids')).to eq([])
  end

  it "discards when #{type} tags given with invalid ID" do
    # specifically when a string ID is used and doesn't have an underscore prefix
    good_tag1 = create(klass || type)
    good_tag2 = create(klass || type)
    taggable.send(type + '_ids=', [good_tag1.id, 'broken', '_'+good_tag2.name])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's')
    expect(tags).to match_array([good_tag1, good_tag2])
  end

  it "only adds #{type} tags once if given multiple times" do
    name = 'Example Tag'
    tag = create(klass || type, name: name)
    old_user = tag.user
    taggable.send(type + '_ids=', ['_' + name, '_' + name, tag.id.to_s, tag.id.to_s])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's')
    tag_ids = taggable.send(type + '_ids')
    expect(tags).to match_array([tag])
    expect(tags.map(&:user)).to match_array([old_user])
    expect(tag_ids).to match_array([tag.id])
  end

  it "orders #{type} tag joins by order added to model" do
    tag1 = create(klass || type)
    tag2 = create(klass || type)
    tag3 = create(klass || type)
    tag4 = create(klass || type)
    tag_table = model_name == 'setting' ? 'tag' : model_name

    taggable.send(type + '_ids=', [tag3.id, '_fake1', '_'+tag1.name, '_fake2', tag4.id])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's').order(tag_table + '_tags.id')
    expect(tags[0]).to eq(tag3)
    expect(tags[2]).to eq(tag1)
    expect(tags[4]).to eq(tag4)
    expect(tags.map(&:name)).to eq([tag3.name, 'fake1', tag1.name, 'fake2', tag4.name])

    taggable.send(type + '_ids=', taggable.send(type + '_ids') + ['_'+tag2.name, '_fake3', '_fake4'])
    taggable.save
    taggable.reload
    tags = taggable.send(type + 's').order(tag_table + '_tags.id')
    tag_ids = taggable.send(type + '_ids')
    expect(tags[0]).to eq(tag3)
    expect(tags[2]).to eq(tag1)
    expect(tags[5]).to eq(tag2)
    expect(tags.map(&:name)).to eq([tag3.name, 'fake1', tag1.name, 'fake2', tag4.name, tag2.name, 'fake3', 'fake4'])
  end
end
