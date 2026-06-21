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

    it "drops declaration values containing angle brackets (style-tag breakout)" do
      result = sanitize('.a { content: "</style><script>alert(1)</script>"; color: red; }')
      expect(result).not_to include('<')
      expect(result).not_to include('script')
      expect(result).to include('color: red')
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

  describe ".dangerous?" do
    it "is false for plain safe CSS" do
      expect(Glowfic::CssSanitizer.dangerous?('.a { color: red; padding: 4px; }')).to be(false)
    end

    it "is false for merely unsupported (but harmless) properties" do
      expect(Glowfic::CssSanitizer.dangerous?('.a { nonsense-prop: 5; }')).to be(false)
    end

    it "is true for !important, external url, fixed positioning, @import and @font-face" do
      expect(Glowfic::CssSanitizer.dangerous?('.a { color: red !important; }')).to be(true)
      expect(Glowfic::CssSanitizer.dangerous?('.a { background: url(https://e/x); }')).to be(true)
      expect(Glowfic::CssSanitizer.dangerous?('.a { position: fixed; }')).to be(true)
      expect(Glowfic::CssSanitizer.dangerous?('@import url(https://e/x);')).to be(true)
      expect(Glowfic::CssSanitizer.dangerous?("@font-face { font-family: x; src: url(https://e/f); }")).to be(true)
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

  describe "additional dangerous vectors" do
    it "drops values containing a javascript: URI" do
      expect(sanitize('.a { background-image: url(javascript:alert(1)); color: red; }')).not_to include('javascript')
      expect(Glowfic::CssSanitizer.dangerous?('.a { background-image: url(javascript:alert(1)); }')).to be(true)
    end

    it "drops a rule whose selector itself smuggles a dangerous value" do
      expect(sanitize('a[href*="javascript:"] { color: red; }')).not_to include('javascript')
    end

    it "drops disallowed at-rules while keeping a following safe rule" do
      result = sanitize('@charset "utf-8"; @namespace url(http://example.com); .a { color: red; }')
      expect(result).to include('color: red')
      expect(result).not_to include('namespace')
      expect(result).not_to include('charset')
    end

    it "ignores declarations with an empty name or value" do
      expect(sanitize('.a { : red; color: ; padding: 4px; }')).to include('padding: 4px')
    end

    it "flags -moz-binding and behavior smuggled in an allowed property value" do
      expect(Glowfic::CssSanitizer.dangerous?('.a { content: "-moz-binding"; }')).to be(true)
      expect(Glowfic::CssSanitizer.dangerous?('.a { content: "behavior: x"; }')).to be(true)
    end

    it "drops an at-rule with a dangerous prelude" do
      expect(sanitize('@supports (background: url(http://evil.example/x)) { .a { color: red; } }')).not_to include('color: red')
    end

    it "drops a disallowed at-rule that has a block" do
      expect(sanitize('@page { margin: 0; } .a { color: red; }')).not_to include('margin')
    end

    it "drops an allowed at-rule whose body sanitizes to nothing" do
      expect(sanitize('@media screen { .a { nonsense-prop: 1; } }')).to eq('')
    end

    it "yields an empty string if the parser blows up" do
      allow(Crass).to receive(:parse).and_raise(StandardError)
      expect(sanitize('.a { color: red; }')).to eq('')
    end
  end

  describe ".scope" do
    def scope(css)
      Glowfic::CssSanitizer.scope(css, ':root:root')
    end

    it "prefixes each style-rule selector with the scope" do
      expect(scope('.post-container { color: red; }')).to include(':root:root .post-container {')
    end

    it "scopes every selector in a comma-separated list" do
      result = scope('.a, .b { color: red; }')
      expect(result).to include(':root:root .a')
      expect(result).to include(':root:root .b')
    end

    it "does not split on commas nested inside :not()/attribute selectors" do
      result = scope(':not(.a, .b) { color: red; }')
      expect(result).to include(':root:root :not(.a, .b)')
      expect(result.scan(':root:root').length).to eq(1)
    end

    it "scopes rules inside @media but leaves keyframe selectors literal" do
      media = scope('@media (max-width: 600px) { .a { color: red; } }')
      expect(media).to include(':root:root .a')

      frames = scope('@keyframes spin { from { opacity: 0; } to { opacity: 1; } }')
      expect(frames).to include('@keyframes spin')
      expect(frames).not_to include(':root:root from')
      expect(frames).to include('from')
    end

    it "returns the input unchanged when it cannot be parsed" do
      allow(Crass).to receive(:parse).and_raise(StandardError)
      expect(scope('.a { color: red; }')).to eq('.a { color: red; }')
    end
  end
end
