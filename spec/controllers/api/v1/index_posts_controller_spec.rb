require "spec_helper"
require "support/shared/api_shared_examples"

RSpec.describe Api::V1::IndexPostsController do
  describe "POST reorder" do
    context "without index_section_id" do
      let(:ordered_ids) { :ordered_post_ids }
      let(:ids_name) { 'post_ids' }
      let(:child_name) { 'post' }

      include_examples "reorder", :index, :index_post
    end

    context "with index_section_id" do
      let(:ordered_ids) { :ordered_post_ids }
      let(:parent_id) { :section_id }
      let(:ids_name) { 'post_ids' }
      let(:child_name) { 'post' }

      include_examples "reorder with sections", :index, :index_section, :index_post, 'section'
    end
  end
end
