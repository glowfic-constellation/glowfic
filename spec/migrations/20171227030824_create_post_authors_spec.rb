require 'spec_helper'

migration_file_name = Dir[Rails.root.join('db/migrate/20171227030824_create_post_authors.rb')].first
require migration_file_name

RSpec.describe CreatePostAuthors do
  let(:migration) { CreatePostAuthors.new }

  describe "#up" do
    before(:each) do
      migration.migrate(:down)

      Post.reset_column_information
      Reply.reset_column_information

      Post.skip_callback(:create, :after, :update_post_authors)
      Reply.skip_callback(:create, :after, :update_post_authors)
      Reply.skip_callback(:create, :after, :notify_other_authors)
      post_with_none = create(:post, subject: 'Post with no replies')

      post_with_all_same = create(:post, subject: 'Post with just one author')
      create(:reply, user: post_with_all_same.user, post: post_with_all_same)

      post_with_many = create(:post, subject: 'Post with many authors')
      singles = Array.new(3) { create(:reply, post: post_with_many) }
      doubles = Array.new(3) do
        user = create(:user)
        Array.new(2) { create(:reply, user: user, post: post_with_many) }
      end

      migration.migrate(:up)

      Post.set_callback(:create, :after, :update_post_authors)
      Reply.set_callback(:create, :after, :update_post_authors)
      Reply.set_callback(:create, :after, :notify_other_authors)

      Post.reset_column_information
      Reply.reset_column_information
    end

    let(:none) { Post.find_by(subject: 'Post with no replies') }
    let(:same) { Post.find_by(subject: 'Post with just one author') }
    let(:many) { Post.find_by(subject: 'Post with many authors') }

    it "handles post with no replies" do
      expect(none.author_ids).to match_array([none.user_id])
      expect(none.authors).to match_array([none.user])
      expect(none.tagging_authors).to match_array([none.user])
      expect(none.joined_authors).to match_array([none.user])

      expect(none.post_authors.length).to eq(1)

      first_author = none.post_authors.order(:user_id).first
      expect(first_author.can_owe).to eq(true)
      expect(first_author.joined).to eq(true)
      expect(first_author.invited_at).to be_nil
      expect(first_author.invited_by).to be_nil
      expect(first_author.joined_at).to eq(none.created_at)
    end

    it "handles solo post" do
      expect(same.author_ids).to match_array([same.user_id])
      expect(same.authors).to match_array([same.user])
      expect(same.tagging_authors).to match_array([same.user])
      expect(same.joined_authors).to match_array([same.user])

      expect(same.post_authors.length).to eq(1)

      first_author = same.post_authors.order(:user_id).first
      expect(first_author.can_owe).to eq(true)
      expect(first_author.joined).to eq(true)
      expect(first_author.invited_at).to be_nil
      expect(first_author.invited_by).to be_nil
      expect(first_author.joined_at).to eq(same.created_at)
    end

    it "handles longer posts" do
      user_ids = [many.user_id] + many.replies.pluck('distinct user_id')
      users = User.where(id: user_ids)
      expect(user_ids.count).to eq(7)
      expect(users.count).to eq(7)

      expect(many.author_ids).to match_array(user_ids)
      expect(many.authors).to match_array(users)
      expect(many.tagging_authors).to match_array(users)
      expect(many.joined_authors).to match_array(users)

      expect(many.post_authors.length).to eq(7)
      ordered_post_authors = many.post_authors.order(:user_id)

      first_author = ordered_post_authors.first
      expect(first_author.joined_at).to eq(many.created_at)

      ordered_post_authors.each do |post_author|
        expect(post_author.can_owe).to eq(true)
        expect(post_author.joined).to eq(true)
        expect(post_author.invited_at).to be_nil
        expect(post_author.invited_by).to be_nil
      end

      replies_created = many.replies.order(:id).pluck(:created_at)
      join_times = [many.created_at]
      join_times += replies_created[0..2]
      0.upto(2) { |i| join_times << replies_created[3 + i * 2] }

      actual_times = ordered_post_authors.pluck(:joined_at)
      expect(join_times).to eq(actual_times)
    end
  end
end
