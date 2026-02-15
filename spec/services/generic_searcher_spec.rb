RSpec.describe Generic::Searcher do
  it "stores the initial search relation" do
    searcher = Generic::Searcher.new(Reply.none)
    expect(searcher.instance_variable_get(:@search_results)).to eq(Reply.none)
  end
end
