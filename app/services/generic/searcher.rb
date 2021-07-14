class Generic::Searcher < Generic::Service
  def initialize(search)
    @search_results = search
    super()
  end
end
