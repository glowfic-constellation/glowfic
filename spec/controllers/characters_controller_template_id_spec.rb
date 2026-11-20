# frozen_string_literal: true
RSpec.describe CharactersController, '#template_id' do
  it "does not let a user put their character in someone else's template (update)" do
    user = create(:user)
    char = create(:character, user: user)
    other_template = create(:template)
    login_as(user)
    put :update, params: { id: char.id, character: { template_id: other_template.id } }
    expect(char.reload.template_id).to be_nil
  end

  it "does not let a user create a character in someone else's template" do
    user = create(:user)
    other_template = create(:template)
    login_as(user)
    post :create, params: { character: { name: 'probe', template_id: other_template.id } }
    expect(Character.where(name: 'probe').first&.template_id).to be_nil
  end
end
