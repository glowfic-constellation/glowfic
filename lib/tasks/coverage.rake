# frozen_string_literal: true
namespace :coverage do
  desc 'Merge parallel_tests SimpleCov results and enforce the coverage threshold'
  task :report do # rubocop:disable Rails/RakeEnvironment -- doesn't need application code
    require 'simplecov'

    result_files = Dir['coverage/parallel/*/.resultset.json']
    if result_files.empty? # rubocop:disable Style/IfUnlessModifier
      abort 'No parallel coverage results found under coverage/parallel/*. Did the test run write coverage?'
    end

    # Collate the per-worker results into one report and apply the same gate the
    # single-process run uses (see spec/spec_helper.rb). Exits non-zero if below.
    SimpleCov.collate(result_files, 'rails') do
      enable_coverage :branch
      # NB: keep in sync with spec/spec_helper.rb minimum_coverage
      minimum_coverage line: 95.2, branch: 88.1
    end
  end
end
