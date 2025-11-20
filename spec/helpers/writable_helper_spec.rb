RSpec.describe WritableHelper do
  describe "#unread_warning" do
    let(:post) { create(:post) }

    before(:each) do
      assign(:post, post)
      without_partial_double_verification do
        allow(helper).to receive(:page).and_return(1)
      end
    end

    it "returns unless replies are present" do
      expect(helper.unread_warning).to eq(nil)
    end

    it "returns on the last page" do
      create(:reply, post: post)
      assign(:replies, post.replies.paginate(page: 1))
      expect(helper.unread_warning).to eq(nil)
    end

    it "returns html on earlier pages" do
      create_list(:reply, 26, post: post)
      assign(:replies, post.replies.paginate(page: 1))
      html = 'You are not on the latest page of the thread '
      html += tag.a('(View unread)', href: helper.unread_path(post), class: 'unread-warning') + ' '
      html += tag.a('(New tab)', href: helper.unread_path(post), class: 'unread-warning', target: '_blank')
      expect(helper.unread_warning).to eq(html)
    end
  end

  describe "#sanitize_simple_link_text" do
    it "remains blank if given blank" do
      text = ''
      expect(helper.sanitize_simple_link_text(text)).to eq(text)
    end

    it "does not malform plain text" do
      text = 'sample text'
      expect(helper.sanitize_simple_link_text(text)).to eq(text)
    end

    it "permits links", :aggregate_failures do
      text = 'here is <a href="http://example.com">a link</a> '
      text += '<a href="https://example.com">another link</a> '
      text += '<a href="/characters/1">yet another link</a>'
      result = helper.sanitize_simple_link_text(text)
      expect(result).to eq(text)
      expect(result).to be_html_safe
    end

    it "removes unpermitted attributes" do
      text = '<a onclick="function(){ alert("bad!");}">test</a>'
      expect(helper.sanitize_simple_link_text(text)).to eq('<a>test</a>')
    end

    it "removes unpermitted elements" do
      text = '<b>test</b> <script type="text/javascript">alert("bad!");</script> <p>text</p>'
      expect(helper.sanitize_simple_link_text(text)).to eq('test   text ')
    end

    it "fixes unending tags" do
      text = '<a>test'
      expect(helper.sanitize_simple_link_text(text)).to eq('<a>test</a>')
    end
  end

  describe "#sanitize_written_content", :aggregate_failures do
    ['rtf', 'html', 'md'].each do |editor_mode|
      # applies only for single-line input
      def format_input(text, editor_mode)
        return text if editor_mode == 'html'
        "<p>#{text}</p>"
      end

      context "shared examples in #{editor_mode} mode" do
        it "is blank if given blank" do
          text = ''
          expect(helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)).to eq("<p>#{text}</p>")
        end

        it "does not malform plain text" do
          text = 'sample text'
          expect(helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)).to eq("<p>#{text}</p>")
        end

        it "permits links" do
          text = 'here is <a href="http://example.com">a link</a> '
          text += '<a href="https://example.com">another link</a> '
          text += '<a href="/characters/1">yet another link</a>'
          expect(helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)).to eq("<p>#{text}</p>")
        end

        it "permits images", :aggregate_failures do
          text = 'images: <img src="http://example.com/image.png"> <img src="https://example.com/image.jpg"> <img src="/image.gif">'
          result = helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)
          expect(result).to eq("<p>#{text}</p>")
          expect(result).to be_html_safe
        end

        it "removes unpermitted attributes" do
          text = '<a onclick="function(){ alert("bad!");}">test</a>'
          expect(helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)).to eq("<p><a>test</a></p>")
        end

        it "permits valid CSS" do
          text = '<a style="color: red;">test</a>'
          expect(helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)).to eq("<p>#{text}</p>")
        end

        it "fixes unending tags" do
          text = '<a>test'
          expect(helper.sanitize_written_content(format_input(text, editor_mode), editor_mode)).to eq("<p><a>test</a></p>")
        end
      end
    end

    context "with linebreak tags" do
      # RTF editor or HTML editor with manual tags
      it "removes unpermitted elements" do
        text = '<b>test</b> <script type="text/javascript">alert("bad!");</script> <p>text</p>'
        result = helper.sanitize_written_content(text, 'rtf')
        expect(result).to eq('<b>test</b>  <p>text</p>')
        expect(result).to be_html_safe
      end

      it "permits some attributes on only some tags", :aggregate_failures do
        text = '<p><a width="100%" href="https://example.com">test</a></p> <hr width="100%">'
        expected = '<p><a href="https://example.com">test</a></p> <hr width="100%">'
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(expected)

        text = '<a width="100%" href="https://example.com">test</a> <hr width="100%">'
        expected = '<p><a href="https://example.com">test</a> </p><hr width="100%"><p></p>'
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)
      end

      it "does not convert linebreaks in text with <br> tags" do
        text = "line1<br>line2\nline3"
        display = text
        expect(helper.sanitize_written_content(text, 'html')).to eq(display)
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(display)

        text = "line1<br/>line2\nline3"
        expect(helper.sanitize_written_content(text, 'html')).to eq(display)
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(display)

        text = "line1<br />line2\nline3"
        expect(helper.sanitize_written_content(text, 'html')).to eq(display)
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(display)
      end

      it "does not convert linebreaks in text with <p> tags" do
        text = "<p>line1</p><p>line2\nline3</p>"
        expect(helper.sanitize_written_content(text, 'html')).to eq(text)
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(text)
      end

      it "does not convert linebreaks in text with complicated <p> tags" do
        text = "<p style=\"width: 100%;\">line1\nline2</p>"
        expect(helper.sanitize_written_content(text, 'html')).to eq(text)
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(text)
      end

      it "does not touch blockquotes" do
        text = "<blockquote>Blah. Blah.<br />Blah.</blockquote>\n<blockquote>Blah blah.</blockquote>\n<p>Blah.</p>"
        expected = "<blockquote>Blah. Blah.<br>Blah.</blockquote>\n<blockquote>Blah blah.</blockquote>\n<p>Blah.</p>"
        expect(helper.sanitize_written_content(text, 'rtf')).to eq(expected)
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected.gsub("\n", "\n\n"))
      end
    end

    context "without linebreak tags" do
      it "automatically converts linebreaks" do
        text = "line1\nline2\n\nline3"
        result = helper.sanitize_written_content(text, 'html')
        expect(result).to eq("<p>line1\n<br>line2</p>\n\n<p>line3</p>")
        expect(result).to be_html_safe
      end

      it "defaults to old linebreak-to-br format when blockquote detected" do
        text = "<blockquote>Blah. Blah.\r\nBlah.\r\n\r\nBlah blah.</blockquote>\r\nBlah."
        expected = "<blockquote>Blah. Blah.<br>Blah.<br><br>Blah blah.</blockquote><br>Blah."
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)
      end

      it "does not mangle large breaks" do
        text = "line1\n\n\nline2"
        expected = "<p>line1</p>\n\n<p>\n<br>line2</p>"
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)

        text = "line1\n\n\n\nline2"
        expected = "<p>line1</p>\n\n<p>&nbsp;</p>\n\n<p>line2</p>" # U+00A0 is NBSP
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)
      end

      it "does not mangle tags continuing over linebreaks" do
        text = "line1<b>text\nline2</b>"
        expected = "<p>line1<b>text\n<br>line2</b></p>"
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)

        text = "line1<b>text\n\nline2</b>"
        expected = "<p>line1<b>text</b></p><b>\n\n</b><p><b>line2</b></p>"
        expect(helper.sanitize_written_content(text, 'html')).to eq(expected)
      end
    end

    context "markdown formatter" do
      it "automatically converts linebreaks" do
        text = "line1\nline2\n\nline3"
        result = helper.sanitize_written_content(text, 'md')
        expect(result).to eq("<p>line1<br>\nline2</p>\n\n<p>line3</p>")
        expect(result).to be_html_safe
      end

      it "supports blockquotes" do
        text = "> Blah. Blah.\r\n> Blah.\r\n>\r\n> Blah blah.\r\n\r\nBlah."
        expected = "<blockquote>\n<p>Blah. Blah.<br>\nBlah.</p>\n\n<p>Blah blah.</p>\n</blockquote>\n\n<p>Blah.</p>"
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)
      end

      skip "does not mangle large breaks" do
        # TODO: markdown renderer doesn't support hard breaks with so many lines
        text = "line1\n\n\nline2"
        expected = "<p>line1</p>\n\n<p>\n<br>line2</p>"
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)

        text = "line1\n\n\n\nline2"
        expected = "<p>line1</p>\n\n<p>&nbsp;</p>\n\n<p>line2</p>" # U+00A0 is NBSP
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)
      end

      it "does not mangle tags continuing over linebreaks" do
        text = "line1<b>text\nline2</b>"
        expected = "<p>line1<b>text<br>\nline2</b></p>"
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)

        text = "line1<b>text\n\nline2</b>"
        expected = "<p>line1<b>text</b></p><b>\n\n</b><p><b>line2</b></p>"
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)
      end

      it "renders markdown" do
        text = "here is _some_ text that has **formatting** in like a link to http://google.com/"
        expected = "<p>here is <em>some</em> text that has <strong>formatting</strong> in like a link to <a href=\"http://google.com/\">http://google.com/</a></p>"
        expect(helper.sanitize_written_content(text, 'md')).to eq(expected)
      end
    end
  end

  describe "#privacy_icon" do
    it "works with alt text" do
      expected = image_tag("/assets/icons/stars_constellation.png", class: 'vmid', title: 'Constellation Users', alt: 'Constellation Users')
      expect(helper.privacy_icon(:registered)).to eq(expected)
    end

    it "works with dark layout switch" do
      expected = image_tag("/assets/icons/stars_constellation_darkmode.png", class: 'vmid', title: 'Constellation Users', alt: 'Constellation Users')
      expect(helper.privacy_icon(:registered, dark_layout: true)).to eq(expected)
    end

    it "works with no alt text" do
      expected = image_tag("/assets/icons/lock.png", class: 'vmid', title: 'Private', alt: '')
      expect(helper.privacy_icon(:private, alt: false)).to eq(expected)
    end
  end

  describe "#post_or_reply_link" do
    it "requires an id" do
      reply = build(:reply)
      expect(helper.post_or_reply_link(reply)).to be_nil
    end

    it "delegates to post_or_reply_mem_link" do
      reply = create(:reply)
      allow(helper).to receive(:post_or_reply_mem_link).and_call_original
      expect(helper).to receive(:post_or_reply_mem_link).with(id: reply.id, klass: Reply)
      helper.post_or_reply_link(reply)
    end
  end

  describe "#post_or_reply_mem_link" do
    it "requires an id" do
      expect(helper.post_or_reply_mem_link(id: nil, klass: '')).to be_nil
    end

    it "handles a reply" do
      reply = create(:reply)
      html = reply_path(reply.id, anchor: "reply-#{reply.id}")
      expect(helper.post_or_reply_mem_link(id: reply.id, klass: Reply)).to eq(html)
    end

    it "handles a post" do
      post = create(:post)
      html = post_path(post.id)
      expect(helper.post_or_reply_mem_link(id: post.id, klass: Post)).to eq(html)
    end
  end
end
