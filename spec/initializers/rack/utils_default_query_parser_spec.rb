RSpec.describe Rack::Utils, ".default_query_parser" do
  # A gallery edit form sends about ten fields per icon, so a few thousand
  # icons is the realistic worst case. Rack's stock cap of 4096 parameters
  # turned a save of a 400-icon gallery into a 404 (see the initializer).
  def query_with(count)
    Array.new(count) { |i| "gallery[galleries_icons_attributes][#{i}][id]=#{i}" }.join('&')
  end

  it "parses a form body far larger than Rack's stock cap of 4096 parameters" do
    parsed = Rack::Utils.parse_nested_query(query_with(10_000))
    expect(parsed['gallery']['galleries_icons_attributes'].size).to eq(10_000)
  end

  it "still refuses a body that is abusive rather than merely large" do
    expect { Rack::Utils.parse_nested_query(query_with(70_000)) }.to raise_error(Rack::QueryParser::QueryLimitError)
  end

  it "keeps Rack's nesting depth limit rather than resetting it" do
    expect(Rack::Utils.param_depth_limit).to eq(32)
  end

  it "raises the multipart part cap to match" do
    expect(Rack::Utils.multipart_total_part_limit).to eq(65_536)
  end
end
