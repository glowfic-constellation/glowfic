# frozen_string_literal: true
RSpec.describe TemplatesController, '#character_ids' do
  it "does not let a user attach someone else's character to their template" do
    user = create(:user)
    template = create(:template, user: user)
    victim_char = create(:character)
    login_as(user)
    put :update, params: { id: template.id, template: { character_ids: [victim_char.id] } }
    expect(victim_char.reload.template_id).to be_nil
  end

  it "does not let a user attach someone else's character on create" do
    user = create(:user)
    victim_char = create(:character)
    login_as(user)
    post :create, params: { template: { name: 'x', character_ids: [victim_char.id] } }
    expect(victim_char.reload.template_id).to be_nil
  end
end
