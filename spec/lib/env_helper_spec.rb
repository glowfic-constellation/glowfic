# `ENV#[]` is the method the helper stubs and the method the failure came
# through, so these examples have to call it. Style/FetchEnvVar would rewrite
# them to `ENV.fetch`, which exercises a different method and proves nothing.

# rubocop:disable-next Style/FetchEnvVar
RSpec.describe EnvHelper do
  # The bug this helper exists to prevent. `with` does not scope a stub to one
  # argument; it replaces the method and rejects every other call. Any code
  # that reads an unrelated environment variable during the example then dies.
  it "shows why the naive stub cannot be used" do
    allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('secret')
    expect { ENV['SOME_OTHER_VARIABLE'] }.to raise_error(RSpec::Mocks::MockExpectationError)
  end

  it "stubs the key it is given" do
    stub_env('ACCOUNT_SECRET', 'secret')
    expect(ENV['ACCOUNT_SECRET']).to eq('secret')
  end

  it "leaves every other variable readable" do
    stub_env('ACCOUNT_SECRET', 'secret')
    expect { ENV['SOME_OTHER_VARIABLE'] }.not_to raise_error
  end

  it "returns the real value for a variable it did not stub" do
    stub_env('ACCOUNT_SECRET', 'secret')
    expect(ENV['RAILS_ENV']).to eq('test')
  end

  # The concrete case that broke CI: Rack initialises
  # BUFFERED_UPLOAD_BYTESIZE_LIMIT by reading this variable when
  # rack/multipart/parser.rb loads. If that load happens inside a stubbed
  # example, the naive stub turns a form POST into a spec failure.
  it "allows the read Rack makes while loading its multipart parser" do
    stub_env('ACCOUNT_SECRET', 'secret')
    expect { ENV['RACK_MULTIPART_BUFFERED_UPLOAD_BYTESIZE_LIMIT'] }.not_to raise_error
  end
end
