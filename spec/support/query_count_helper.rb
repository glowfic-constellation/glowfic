module QueryCountHelper
  # Counts the SQL queries run by the block, ignoring schema lookups, transactions and query-cache hits.
  # If matching is given, only counts queries whose SQL matches it.
  def count_queries(matching: nil, &)
    count = 0
    counter = lambda do |*, payload|
      next if payload[:cached] || %w(SCHEMA TRANSACTION).include?(payload[:name])
      next if matching && !matching.match?(payload[:sql])
      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  # Checks that loading the path doesn't run more queries after the block adds more records to the page,
  # i.e. that the page doesn't run a query per record.
  def expect_constant_queries(path, matching: nil, &)
    # each count follows a warm-up request, so caches (e.g. unread message counts) are populated in both
    get path
    expect(response).to have_http_status(200)
    baseline = count_queries(matching: matching) { get path }
    yield
    get path
    expect(count_queries(matching: matching) { get path }).to eq(baseline)
  end
end
