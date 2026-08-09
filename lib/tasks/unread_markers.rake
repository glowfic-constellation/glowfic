# frozen_string_literal: true

namespace :post_views do
  desc "Backfill last_read_reply_id from read_at on post views that don't yet have one"
  task backfill_last_read_reply: :environment do
    scope = Post::View.where.not(read_at: nil).where(last_read_reply_id: nil)
    total = scope.count
    puts "Backfilling last_read_reply_id for #{total} post views"

    done = 0
    scope.in_batches(of: 5000) do |batch|
      # the last reply (including the written) read before read_at; the fallback covers
      # read_at values predating even the written reply, e.g. from mark-unread-here's
      # one-second epsilon on a first reply posted within a second of the post
      done += batch.update_all(<<~SQL.squish) # rubocop:disable Rails/SkipsModelValidations
        last_read_reply_id = COALESCE(
          (SELECT replies.id FROM replies
            WHERE replies.post_id = post_views.post_id AND replies.created_at <= post_views.read_at
            ORDER BY replies.reply_order DESC LIMIT 1),
          (SELECT written.id FROM replies written WHERE written.post_id = post_views.post_id AND written.reply_order = 0)
        )
      SQL
      puts "  #{done} / #{total}"
    end
    puts "Done."
  end
end
