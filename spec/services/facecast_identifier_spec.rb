RSpec.describe FacecastIdentifier do
  let(:api_key) { 'test-key' }
  let(:image_url) { 'https://glowfic-dev.s3.amazonaws.com/users/1/icons/rem.png' }

  before(:each) do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('SAUCENAO_API_KEY', nil).and_return(api_key)
  end

  def stub_saucenao(body:, status: 200)
    stub_request(:get, /saucenao\.com/).to_return(
      status: status,
      body: body.is_a?(String) ? body : body.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
  end

  describe ".enabled?" do
    it "is true when an api key is configured" do
      expect(FacecastIdentifier).to be_enabled
    end

    context "without an api key" do
      let(:api_key) { nil }

      it "is false" do
        expect(FacecastIdentifier).not_to be_enabled
      end
    end
  end

  describe "#identify" do
    context "without an api key" do
      let(:api_key) { nil }

      it "raises a configuration error" do
        expect { FacecastIdentifier.new(image_url).identify }.to raise_error(FacecastIdentifier::Error, /not configured/)
      end
    end

    it "raises when there is no image" do
      expect { FacecastIdentifier.new('').identify }.to raise_error(FacecastIdentifier::Error, /no image/)
    end

    it "returns 'Character (Source)' for a confident anime match" do
      stub_saucenao(body: {
        results: [{
          header: { similarity: '92.5' },
          data: { characters: 'Rem', material: 'Re:Zero kara Hajimeru Isekai Seikatsu' },
        }],
      })
      expect(FacecastIdentifier.new(image_url).identify).to eq('Rem (Re:Zero kara Hajimeru Isekai Seikatsu)')
    end

    it "falls back to the source when there is no character" do
      stub_saucenao(body: { results: [{ header: { similarity: '80' }, data: { source: 'Some Artwork' } }] })
      expect(FacecastIdentifier.new(image_url).identify).to eq('Some Artwork')
    end

    it "takes the first entry when a field is a newline-separated list" do
      stub_saucenao(body: {
        results: [{ header: { similarity: '77' }, data: { characters: "Rem\nRam", material: 'Re:Zero' } }],
      })
      expect(FacecastIdentifier.new(image_url).identify).to eq('Rem (Re:Zero)')
    end

    it "returns nil for a low-confidence match" do
      stub_saucenao(body: { results: [{ header: { similarity: '12.3' }, data: { characters: 'Rem' } }] })
      expect(FacecastIdentifier.new(image_url).identify).to be_nil
    end

    it "returns nil when there are no results" do
      stub_saucenao(body: { results: [] })
      expect(FacecastIdentifier.new(image_url).identify).to be_nil
    end

    it "raises when SauceNAO returns an error status" do
      stub_saucenao(body: 'rate limited', status: 429)
      expect { FacecastIdentifier.new(image_url).identify }.to raise_error(FacecastIdentifier::Error, /status 429/)
    end

    it "raises a friendly error when SauceNAO is unreachable" do
      stub_request(:get, /saucenao\.com/).to_raise(Errno::ECONNREFUSED)
      expect { FacecastIdentifier.new(image_url).identify }.to raise_error(FacecastIdentifier::Error, /could not be reached/)
    end
  end
end
