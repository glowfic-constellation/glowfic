RSpec.shared_examples "reorder" do |parent, child|
  let(:user) { create(:user) }
  let(:parent1) { create(parent, user: user) }
  let(:parent2) { create(parent, user: user) }
  let!(:child1) { create(child, parent => parent1) }
  let!(:child2) { create(child, parent => parent1) }
  let!(:child3) { create(child, parent => parent1) }
  let!(:child4) { create(child, parent => parent1) }
  let!(:child5) { create(child, parent => parent2) }

  parent_name = parent.to_s.humanize.downcase

  it "requires login", :show_in_doc do
    post :reorder
    expect(response).to have_http_status(401)
    expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
  end

  it "requires a #{parent_name} you have access to" do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)

    post_ids = [child2, child1].map(&:id)

    login
    post :reorder, params: { ordered_ids => post_ids }
    expect(response).to have_http_status(403)
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
  end

  it "requires a single #{parent_name}" do
    child6 = create(child, parent => parent2)

    expect(child1.reload.order).to eq(0)
    expect(child5.reload.order).to eq(0)
    expect(child6.reload.order).to eq(1)

    post_ids = [child6, child5, child1].map(&:id)
    login_as(user)
    post :reorder, params: { ordered_ids => post_ids }
    expect(response).to have_http_status(422)
    expect(response.json['errors'][0]['message']).to eq("#{child_name.capitalize.pluralize} must be from one #{parent_name}")
    expect(child1.reload.order).to eq(0)
    expect(child5.reload.order).to eq(0)
    expect(child6.reload.order).to eq(1)
  end

  it "requires valid ids" do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)

    login_as(user)
    post :reorder, params: { ordered_ids => [-1] }
    expect(response).to have_http_status(404)
    expect(response.json['errors'][0]['message']).to eq("Some #{child_name.pluralize} could not be found: -1")
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
  end

  it "works for valid changes", :show_in_doc do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
    expect(child3.reload.order).to eq(2)
    expect(child4.reload.order).to eq(3)
    expect(child5.reload.order).to eq(0)

    post_ids = [child3, child1, child4, child2].map(&:id)

    login_as(user)
    post :reorder, params: { ordered_ids => post_ids }
    expect(response).to have_http_status(200)
    expect(response.json).to eq({ids_name => post_ids})
    expect(child1.reload.order).to eq(1)
    expect(child2.reload.order).to eq(3)
    expect(child3.reload.order).to eq(0)
    expect(child4.reload.order).to eq(2)
    expect(child5.reload.order).to eq(0)
  end

  it "works when specifying valid subset", :show_in_doc do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
    expect(child3.reload.order).to eq(2)
    expect(child4.reload.order).to eq(3)
    expect(child5.reload.order).to eq(0)

    post_ids = [child3, child1].map(&:id)

    login_as(user)
    post :reorder, params: { ordered_ids => post_ids }
    expect(response).to have_http_status(200)
    expect(response.json).to eq({ids_name => [child3, child1, child2, child4].map(&:id)})
    expect(child1.reload.order).to eq(1)
    expect(child2.reload.order).to eq(2)
    expect(child3.reload.order).to eq(0)
    expect(child4.reload.order).to eq(3)
    expect(child5.reload.order).to eq(0)
  end
end

RSpec.shared_examples "reorder with sections" do |grandparent, parent, child, parent_name|
  grandparent_name ||= grandparent.to_s.humanize.downcase

  let(:user) { create(:user) }
  let(:grandparent1) { create(grandparent, user: user)}
  let(:parent1) { create(parent, grandparent => grandparent1) }
  let(:parent2) { create(parent, grandparent => grandparent1) }
  let!(:child1) { create(child, grandparent => grandparent1, parent => parent1) }
  let!(:child2) { create(child, grandparent => grandparent1, parent => parent1) }
  let!(:child3) { create(child, grandparent => grandparent1, parent => parent1) }
  let!(:child4) { create(child, grandparent => grandparent1, parent => parent1) }
  let!(:child5) { create(child, grandparent => grandparent1, parent => parent2) }
  let(:error_message) { "Posts must be from one specified #{parent_name} in the #{grandparent_name}, or no #{parent_name}" }

  it "requires a #{grandparent_name} you have access to" do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)

    post_ids = [child2, child1].map(&:id)

    login
    post :reorder, params: { ordered_ids => post_ids, parent_id => parent1.id }
    expect(response).to have_http_status(403)
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
  end

  it "requires a single #{parent_name}" do
    child6 = create(child, grandparent => grandparent1, parent => parent2)

    expect(child1.reload.order).to eq(0)
    expect(child5.reload.order).to eq(0)
    expect(child6.reload.order).to eq(1)

    post_ids = [child6, child5, child1].map(&:id)
    login_as(user)
    post :reorder, params: { ordered_ids => post_ids, parent_id => parent1.id }
    expect(response).to have_http_status(422)
    expect(response.json['errors'][0]['message']).to eq(error_message)
    expect(child1.reload.order).to eq(0)
    expect(child5.reload.order).to eq(0)
    expect(child6.reload.order).to eq(1)
  end

  it "requires valid #{parent_name} id" do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)

    post_ids = [child2.id, child1.id]
    login_as(user)
    post :reorder, params: { ordered_ids => post_ids, parent_id => 0 }
    expect(response.json['errors'][0]['message']).to eq(error_message)
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
  end

  it "requires correct #{parent_name} id" do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)

    post_ids = [child2, child1].map(&:id)
    login_as(user)
    post :reorder, params: { ordered_ids => post_ids, parent_id => parent2.id }
    expect(response).to have_http_status(422)
    expect(response.json['errors'][0]['message']).to eq(error_message)
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
  end

  it "requires no #{parent_name} id if posts not in #{parent}" do
    child1 = create(child, grandparent => grandparent1)
    child2 = create(child, grandparent => grandparent1)

    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)

    post_ids = [child2.id, child1.id]
    login_as(user)
    post :reorder, params: { ordered_ids => post_ids, parent_id => parent1.id }
    expect(response).to have_http_status(422)
    expect(response.json['errors'][0]['message']).to eq(error_message)
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
  end

  it "requires valid ids" do
    login_as(user)
    post :reorder, params: { ordered_ids => [-1], parent_id => parent1.id }
    expect(response).to have_http_status(404)
    expect(response.json['errors'][0]['message']).to eq('Some posts could not be found: -1')
  end

  it "works for valid changes", :show_in_doc do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
    expect(child3.reload.order).to eq(2)
    expect(child4.reload.order).to eq(3)
    expect(child5.reload.order).to eq(0)

    post_ids = [child3, child1, child4, child2].map(&:id)

    login_as(user)
    post :reorder, params: { ordered_ids => post_ids, parent_id => parent1.id }
    expect(response).to have_http_status(200)
    expect(response.json).to eq({ids_name => post_ids})
    expect(child1.reload.order).to eq(1)
    expect(child2.reload.order).to eq(3)
    expect(child3.reload.order).to eq(0)
    expect(child4.reload.order).to eq(2)
    expect(child5.reload.order).to eq(0)
  end

  it "works when specifying valid subset", :show_in_doc do
    expect(child1.reload.order).to eq(0)
    expect(child2.reload.order).to eq(1)
    expect(child3.reload.order).to eq(2)
    expect(child4.reload.order).to eq(3)
    expect(child5.reload.order).to eq(0)

    post_ids = [child3, child1].map(&:id)

    login_as(user)
    post :reorder, params: { ordered_ids => post_ids, parent_id => parent1.id }
    expect(response).to have_http_status(200)
    expect(response.json).to eq({ids_name => [child3, child1, child2, child4].map(&:id)})
    expect(child1.reload.order).to eq(1)
    expect(child2.reload.order).to eq(2)
    expect(child3.reload.order).to eq(0)
    expect(child4.reload.order).to eq(3)
    expect(child5.reload.order).to eq(0)
  end
end
