class AddLastFieldsToPost < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :last_user_id, :integer
    add_column :posts, :last_reply_id, :integer
    add_column :posts, :edited_at, :datetime
    ActiveRecord::Base.record_timestamps = false
    begin
      Post.all.each do |post|
        if (last_reply = post.replies.order('created_at desc').first)
          post.last_reply_id = last_reply.id
          post.last_user_id = last_reply.user_id
        else
          post.last_user_id = post.user_id
        end

        last_edit = post.audits.where(action: 'update').reject { |a| a.audited_changes.keys == ['privacy'] }.last
        if last_edit
          post.edited_at = last_edit.created_at
        else
          post.edited_at = post.updated_at
        end

        post.skip_edited = true
        post.save_without_auditing
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end
end
