RSpec.describe Icon::Reuploader do
  describe 'validations' do
    it 'rejects malformed url'
    it 'rejects non-image'
    it 'rejects too large file'
  end

  pending 'works' do
    create(:icon, url: 'https://pbs.twimg.com/profile_images/482603626/avatar.png') # from seeds
    # scrapes image correctly
    # uploads image correct
    # updates icon correctly
  end

  it 'handles unusual file-types'

  it 'handles large icons'
end
