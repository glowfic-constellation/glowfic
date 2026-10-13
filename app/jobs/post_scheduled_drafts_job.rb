# frozen_string_literal: true
# Posts (promotes into replies / "tags") any reply drafts whose scheduled time has
# arrived, like a Tumblr-style queue. Intended to be run periodically, e.g. via a
# scheduler / cron invoking `rake drafts:post_scheduled`.
class PostScheduledDraftsJob < ApplicationJob
  queue_as :high

  # Arbitrary, stable key identifying this job's Postgres advisory lock. Guards
  # against two overlapping ticks both promoting the same draft (which would post
  # a duplicate reply, since promotion is create-reply-then-destroy-draft).
  ADVISORY_LOCK_KEY = 8_073_351_402_197_531 # "post scheduled drafts"

  def perform
    with_advisory_lock do
      # Promote in scheduled order (id as a stable tiebreaker) so that when several
      # drafts on the same post come due in one tick, the earlier-scheduled tag lands
      # first. NB: we can't use find_each here, as it forces primary-key ordering.
      ReplyDraft.due_for_posting.order(:scheduled_at, :id).each do |draft|
        begin
          draft.post_as_reply!
        rescue ActiveRecord::RecordInvalid => e
          # The draft can no longer be posted (e.g. the author lost write access, or
          # the post was locked). Clear the schedule so it stops retrying but survives
          # as an ordinary draft, and let the author know.
          self.class.notify_exception(e, draft.id)
          draft.update_column(:scheduled_at, nil) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end

  private

  # Runs the block only if this process wins a session-level advisory lock, so a
  # tick started while another is still running exits immediately instead of
  # double-processing due drafts. pg_try_advisory_lock is non-blocking; the lock is
  # tied to the connection, so we run everything on one checked-out connection and
  # always release it.
  def with_advisory_lock
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      if connection.select_value("SELECT pg_try_advisory_lock(#{ADVISORY_LOCK_KEY})")
        begin
          yield
        ensure
          connection.select_value("SELECT pg_advisory_unlock(#{ADVISORY_LOCK_KEY})")
        end
      else
        Rails.logger.info("#{self.class} skipped: another tick holds the advisory lock")
      end
    end
  end
end
