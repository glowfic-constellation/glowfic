# frozen_string_literal: true
require "spec_helper"

# Temporary spec to verify the CI job summary surfaces rspec failures correctly.
# Remove this file once that's confirmed.
RSpec.describe "CI intentional failure" do # rubocop:disable RSpec/DescribeClass -- temporary, not testing a class
  it "fails on purpose" do
    expect(1).to eq(2) # rubocop:disable RSpec/ExpectActual -- temporary, intentional failure
  end
end
