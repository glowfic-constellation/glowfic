require "spec_helper"
require "support/shared/api_shared_examples"

RSpec.describe Api::V1::IndexSectionsController do
  describe "POST reorder" do
    let(:ordered_ids) { :ordered_section_ids }
    let(:ids_name) { 'section_ids' }
    let(:child_name) { 'section' }

    include_examples "reorder", :index, :index_section
  end
end
