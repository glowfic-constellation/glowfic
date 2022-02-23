RSpec.describe ApplicationHelper do
  describe "#breakable_text" do
    it "leaves blank strings intact" do
      expect(helper.send(:breakable_text, nil)).to eq(nil)
      expect(helper.send(:breakable_text, '')).to eq('')
    end

    it "does not do anything special to linebreaks" do
      expect(helper.send(:breakable_text, "text\ntext")).to eq("text\ntext")
      expect(helper.send(:breakable_text, "text\r\ntext")).to eq("text\r\ntext")
    end

    it "escapes HTML elements" do
      text = "screenname <b>text</b> &amp; more text"
      expected = "screenname &lt;b&gt;text&lt;/b&gt; &amp;amp; more text"
      result = helper.send(:breakable_text, text)
      expect(result).to eq(expected)
      expect(result).to be_html_safe
    end

    it "leaves simple text intact" do
      text = "screenname"
      expected = text
      expect(helper.send(:breakable_text, text)).to eq(expected)
    end

    it "leaves hyphenated text intact" do
      text = "screen-name"
      expected = text
      expect(helper.send(:breakable_text, text)).to eq(expected)

      text = "-screen-name-"
      expected = text
      expect(helper.send(:breakable_text, text)).to eq(expected)
    end

    it "adds wordbreak opportunities after underscores" do
      text = "screen_name"
      expected = "screen_<wbr>name"
      expect(helper.send(:breakable_text, text)).to eq(expected)
    end
  end
end
