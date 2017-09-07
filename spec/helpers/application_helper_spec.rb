require "spec_helper"

RSpec.describe ApplicationHelper do
  describe "#sanitize_post_description" do
    it "remains blank if given blank" do
      text = ''
      expect(helper.sanitize_post_description(text)).to eq(text)
    end

    it "does not malform plain text" do
      text = 'sample text'
      expect(helper.sanitize_post_description(text)).to eq(text)
    end

    it "permits links" do
      text = 'here is <a href="http://example.com">a link</a>'
      expect(helper.sanitize_post_description(text)).to eq(text)
    end

    it "removes unpermitted attributes" do
      text = '<a onclick="function(){ alert("bad!");}">test</a>'
      expect(helper.sanitize_post_description(text)).to eq('<a>test</a>')
    end

    it "removes unpermitted elements" do
      text = '<b>test</b> <script type="text/javascript">alert("bad!");</script> <p>text</p>'
      expect(helper.sanitize_post_description(text)).to eq('test alert("bad!");  text ')
    end

    it "fixes unending tags" do
      text = '<a>test'
      expect(helper.sanitize_post_description(text)).to eq('<a>test</a>')
    end
  end

  describe "#sanitize_written_content" do
    it "is blank if given blank" do
      text = ''
      expect(helper.sanitize_written_content(text)).to eq("<p>#{text}</p>")
    end

    it "does not malform plain text" do
      text = 'sample text'
      expect(helper.sanitize_written_content(text)).to eq("<p>#{text}</p>")
    end

    it "permits links" do
      text = 'here is <a href="http://example.com">a link</a>'
      expect(helper.sanitize_written_content(text)).to eq("<p>#{text}</p>")
    end

    it "removes unpermitted attributes" do
      text = '<a onclick="function(){ alert("bad!");}">test</a>'
      expect(helper.sanitize_written_content(text)).to eq('<p><a>test</a></p>')
    end

    it "removes unpermitted elements" do
      text = '<b>test</b> <script type="text/javascript">alert("bad!");</script> <p>text</p>'
      expect(helper.sanitize_written_content(text)).to eq('<b>test</b> alert("bad!"); <p>text</p>')
    end

    it "fixes unending tags" do
      text = '<a>test'
      expect(helper.sanitize_written_content(text)).to eq('<p><a>test</a></p>')
    end

    it "automatically converts linebreaks in text without manual linebreaking" do
      text = "line1\nline2\n\nline3"
      expect(helper.sanitize_written_content(text)).to eq("<p>line1\n<br>line2</p>\n\n<p>line3</p>")
    end

    it "does not convert linebreaks in text with <br> tags" do
      text = "line1<br>line2\nline3"
      display = text
      expect(helper.sanitize_written_content(text)).to eq(display)

      text = "line1<br/>line2\nline3"
      expect(helper.sanitize_written_content(text)).to eq(display)

      text = "line1<br />line2\nline3"
      expect(helper.sanitize_written_content(text)).to eq(display)
    end

    it "does not convert linebreaks in text with <p> tags" do
      text = "<p>line1</p><p>line2\nline3</p>"
      expect(helper.sanitize_written_content(text)).to eq(text)
    end

    it "defaults to old linebreak-to-br format when blockquote detected" do
      text = "<blockquote>Blah. Blah.\r\nBlah.\r\n\r\nBlah blah.</blockquote>\r\nBlah."
      expected = "<blockquote>Blah. Blah.\n<br>Blah.\n<br>\n<br>Blah blah.</blockquote>\n<br>Blah."
      expect(helper.sanitize_written_content(text)).to eq(expected)
    end

    it "does not touch blockquotes if <br> or <p> detected" do
      text = "<blockquote>Blah. Blah.<br />Blah.</blockquote>\r\n<blockquote>Blah blah.</blockquote>\r\n<p>Blah.</p>"
      expected = "<blockquote>Blah. Blah.<br>Blah.</blockquote>\n<blockquote>Blah blah.</blockquote>\n<p>Blah.</p>"
      expect(helper.sanitize_written_content(text)).to eq(expected)
    end

    it "does not mangle large breaks in HTML mode" do
      text = "line1\n\n\nline2"
      expected = "<p>line1</p>\n\n<p>\n<br>line2</p>"
      expect(helper.sanitize_written_content(text)).to eq(expected)

      text = "line1\n\n\n\nline2"
      expected = "<p>line1</p>\n\n<p></p>\n\n<p>line2</p>"
      expect(helper.sanitize_written_content(text)).to eq(expected)
    end
  end
end
