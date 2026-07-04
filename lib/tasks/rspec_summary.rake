# frozen_string_literal: true
namespace :rspec_summary do
  desc 'Summarize failed examples from parallel_tests JSON output into a GitHub Actions job summary'
  task :report do # rubocop:disable Rails/RakeEnvironment -- doesn't need application code
    require 'json'

    result_files = Dir['tmp/rspec_output/rspec_*.json']
    if result_files.empty?
      warn 'No rspec JSON result files found under tmp/rspec_output/ -- skipping failure summary.'
      next
    end

    failures = result_files.flat_map do |path|
      JSON.parse(File.read(path)).fetch('examples', []).select { |example| example['status'] == 'failed' }
    rescue JSON::ParserError => e
      warn "Skipping unparseable rspec result file #{path}: #{e.message}"
      []
    end

    summary_path = ENV.fetch('GITHUB_STEP_SUMMARY', nil)
    out = summary_path ? File.open(summary_path, 'a') : $stdout
    begin
      if failures.empty?
        out.puts '## RSpec failures'
        out.puts
        out.puts 'No failed examples were recorded in the JSON output (check raw logs for crashes, timeouts, or OOM kills).'
        next
      end

      out.puts "## RSpec failures (#{failures.size})"
      failures.each_with_index do |example, index|
        message = example.dig('exception', 'message').to_s.strip
        # limit backtrace shown so the summary doesn't get too long for many failures
        backtrace = Array(example.dig('exception', 'backtrace')).first(10).join("\n")

        out.puts
        out.puts "### #{index + 1}. #{example['full_description']}"
        out.puts "`#{example['file_path']}:#{example['line_number']}`"
        out.puts
        out.puts '```'
        out.puts message
        out.puts '```'
        next if backtrace.empty?

        out.puts
        out.puts '<details><summary>Backtrace</summary>'
        out.puts
        out.puts '```'
        out.puts backtrace
        out.puts '```'
        out.puts '</details>'
      end
    ensure
      out.close if summary_path
    end
  end
end
