RSpec.describe ProfileSampler do
  let(:app) { ->(_env) { [200, {}, ['ok']] } }
  let(:uploads) { Queue.new }
  let(:uploader) { ->(key, result) { uploads << [key, result] } }

  def env(path='/posts/1?per_page=all')
    Rack::MockRequest.env_for(path).merge(
      'action_dispatch.request.path_parameters' => { controller: 'posts', action: 'show', id: '1' },
    )
  end

  it "passes requests through untouched when off" do
    middleware = ProfileSampler.new(app, rate: 0, uploader: uploader)
    expect(Vernier).not_to receive(:profile)
    expect(middleware.call(env)).to eq([200, {}, ['ok']])
  end

  it "profiles a sampled request and uploads it in the background" do
    middleware = ProfileSampler.new(app, rate: 1, uploader: uploader)
    expect(middleware.call(env)).to eq([200, {}, ['ok']])

    key, result = Timeout.timeout(5) { uploads.pop }
    aggregate_failures do
      expect(key).to match(/\Aprofiles\/\d{4}-\d{2}-\d{2}\/\d{6}-posts-show-200-\d+ms-\h{16}\.json\.gz\z/)
      expect(key).not_to include('per_page')
      expect(result).to be_a(Vernier::Result)
      expect(Zlib.gunzip(result.to_firefox(gzip: true))).to include('"meta"')
    end
  end

  it "skips profiling while another profile is running in the process" do
    middleware = ProfileSampler.new(app, rate: 1, uploader: uploader)
    middleware.instance_variable_get(:@lock).lock
    expect(Vernier).not_to receive(:profile)
    expect(middleware.call(env)).to eq([200, {}, ['ok']])
  end

  it "returns the response when the upload fails" do
    middleware = ProfileSampler.new(app, rate: 1, uploader: ->(_key, _result) { raise 'S3 is down' })
    expect(middleware.call(env)).to eq([200, {}, ['ok']])
  end

  it "caps the rate from the environment" do
    stub_env('PROFILE_SAMPLE_RATE', '0.5')
    expect(ProfileSampler.rate).to eq(described_class::MAX_RATE)
    stub_env('PROFILE_SAMPLE_RATE', nil)
    expect(ProfileSampler.rate).to eq(0)
  end

  it "sits after AnonLoadShed so shed requests are not profiled" do
    stack = Rails.application.middleware.map(&:klass)
    expect(stack.index(ProfileSampler)).to be > stack.index(AnonLoadShed)
  end
end
