RSpec.describe "About pages" do
  scenario "Terms of Service page" do
    visit tos_path
    expect(page).to have_selector('#tos-content h1', exact_text: 'Glowfic Constellation Terms of Service')
  end

  scenario "Privacy Policy page" do
    visit privacy_path
    expect(page).to have_selector('#privacy-content h1', exact_text: 'Privacy Policy')
  end

  scenario "Contact Us page" do
    visit contact_path
    expect(page).to have_selector('#contact-content h1', exact_text: 'Contact the Constellation')
  end

  scenario "DMCA Policy page" do
    visit dmca_path
    expect(page).to have_selector('#dmca-content h1', exact_text: 'Glowfic Constellation DMCA Policy')
  end
end
