require "rails_helper"

RSpec.describe Glowfic::CssSanitizer do
  def sanitize(css)
    described_class.call(css)
  end

  describe "allowed styling" do
    it "keeps allowlisted declarations" do
      result = sanitize('.post-container { color: #fff; background-color: #222; padding: 4px; }')
      expect(result).to include('color: #fff')
      expect(result).to include('background-color: #222')
      expect(result).to include('padding: 4px')
    end

    it "keeps vendor-prefixed forms of allowed properties" do
      expect(sanitize('.a { -webkit-transform: scale(2); }')).to include('-webkit-transform: scale(2)')
    end

    it "keeps custom properties whose values are safe" do
      expect(sanitize(':root { --accent: #f0f; }')).to include('--accent: #f0f')
    end

    it "keeps safe at-rules and their inner rules" do
      result = sanitize('@media (max-width: 600px) { .a { display: none; } }')
      expect(result).to include('@media (max-width: 600px)')
      expect(result).to include('display: none')
    end

    it "keeps keyframes" do
      result = sanitize('@keyframes spin { from { opacity: 0; } to { opacity: 1; } }')
      expect(result).to include('@keyframes spin')
      expect(result).to include('opacity: 1')
    end

    it "returns an empty string for blank input" do
      expect(sanitize('')).to eq('')
      expect(sanitize(nil)).to eq('')
      expect(sanitize('   ')).to eq('')
    end
  end

  describe "stripping !important" do
    it "removes !important so the app can always override" do
      result = sanitize('.a { display: none !important; }')
      expect(result).to include('display: none')
      expect(result).not_to include('!important')
    end
  end

  describe "blocking external resources" do
    it "drops @import" do
      expect(sanitize('@import url(https://evil.example/x.css); .a { color: red; }')).not_to include('import')
    end

    it "drops declarations with external url()" do
      result = sanitize('.a { background: url(https://evil.example/track.png); color: red; }')
      expect(result).not_to include('url(')
      expect(result).not_to include('evil.example')
      expect(result).to include('color: red')
    end

    it "drops @font-face (external font loading)" do
      expect(sanitize("@font-face { font-family: x; src: url(https://evil.example/f.woff); }")).not_to include('font-face')
    end

    it "allows data: URIs" do
      css = '.a { background-image: url(data:image/png;base64,iVBORw0KGgo=); }'
      expect(sanitize(css)).to include('data:image/png')
    end

    it "blocks url() regardless of quoting/casing/whitespace" do
      expect(sanitize(".a { background: URL( 'http://e/x' ); }")).not_to include('http')
      expect(sanitize('.a { background: url("//e/x"); }')).not_to include('url(')
    end
  end

  describe "blocking clickjacking and script vectors" do
    it "drops position: fixed and position: sticky" do
      expect(sanitize('.a { position: fixed; top: 0; }')).not_to include('position: fixed')
      expect(sanitize('.a { position: sticky; }')).not_to include('position: sticky')
    end

    it "allows position: relative and absolute" do
      expect(sanitize('.a { position: relative; }')).to include('position: relative')
    end

    it "drops legacy expression() values" do
      expect(sanitize('.a { width: expression(alert(1)); }')).not_to include('expression')
    end

    it "drops -moz-binding and behavior" do
      expect(sanitize('.a { -moz-binding: url(x.xml); }')).not_to include('binding')
      expect(sanitize('.a { behavior: url(x.htc); }')).not_to include('behavior')
    end
  end

  describe "dropping unknown / unsafe properties" do
    it "drops properties that are not allowlisted" do
      expect(sanitize('.a { color: red; nonsense-prop: 5; }')).not_to include('nonsense-prop')
    end

    it "drops a custom property whose value smuggles an external url" do
      expect(sanitize(':root { --x: url(https://evil.example/a); }')).not_to include('evil.example')
    end
  end

  describe "robustness" do
    it "enforces a maximum length" do
      huge = '.a { color: red; }' + ('/* pad */' * 200_000)
      expect(sanitize(huge).bytesize).to be <= described_class::MAX_LENGTH
    end

    it "returns a string (never raises) on malformed input" do
      expect(sanitize('.a { color: ; } } garbage {{{')).to be_a(String)
    end
  end
end
