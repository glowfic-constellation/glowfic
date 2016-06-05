class AddTaggedAtToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :tagged_at, :datetime
    ActiveRecord::Base.record_timestamps = false
    begin
      Post.all.each do |post|
        tagged_at = [post.created_at, post.replies.map(&:created_at)].flatten.max
        post.tagged_at = tagged_at
        post.skip_edited = true
        post.save_without_auditing
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end
end
