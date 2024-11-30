module SpecTestHelper
  def login_as(user)
    request.session[:user_id] = user.id
  end

  def login
    login_as(create(:user))
  end

  RSpec::Matchers.define :match_hash do |expected|
    match do |actual|
      @actual = actual.is_a?(Hash) ? transform(actual) : actual
      @expected = expected.is_a?(Hash) ? transform(expected) : expected
      values_match?(@expected, @actual)
    end

    def transform(parameter)
      parameter.transform_keys! { |k| k.is_a?(Symbol) ? k.to_s : k }
      parameter.transform_values! { |v| transform_element(v) }
    end

    def transform_element(ele)
      if ele.is_a?(ActiveRecord::Relation)
        ele = ele.ordered if ele.respond_to?(:ordered)
        ele.to_a
      elsif ele.is_a?(Array)
        ele.map { |e| transform_element(e) }
      elsif ele.is_a?(Hash)
        transform(ele)
      elsif ele.is_a?(ActiveSupport::TimeWithZone)
        ele.in_time_zone.iso8601(3)
      elsif ele.is_a?(Symbol)
        ele.to_s
      else
        ele
      end
    end

    diffable
    attr_reader :actual, :expected
  end
end

def stub_fixture(url, filename)
  url = url.gsub(/\#cmt\d+$/, '')
  file = Rails.root.join('spec', 'support', 'fixtures', filename + '.html')
  stub_request(:get, url).to_return(status: 200, body: File.new(file))
end

def structured_html(html)
  # given <img src="foo.jpg">, returns [{ tag: "img", path: "/html/body/img", attrs: { src: "foo.jpg" } }]
  # useful for ensuring exact structure of HTML returned, without depending on formatting or ordering-specific details.
  # handles both element nodes and text nodes.
  elements = []
  Capybara.string(html).find('body').native.traverse do |n|
    next if n.node_name == "body"
    elements << n
  end
  elements.map do |n|
    if n.element?
      { tag: n.node_name, path: n.path, attrs: n.attributes.transform_keys(&:to_sym).transform_values(&:value) }
    else
      { tag: n.node_name, path: n.path, content: n.content }
    end
  end
end

RSpec::Matchers.define :eq_structured_html do |expected|
  match do |actual|
    @actual = structured_html(actual).sort_by(&:to_s)
    @expected = if expected.is_a?(String)
      structured_html(expected)
    else
      expected
    end.sort_by(&:to_s)
    values_match?(@expected, @actual)
  end

  diffable
  attr_reader :actual, :expected
end
