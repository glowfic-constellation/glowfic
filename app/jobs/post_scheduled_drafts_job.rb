# frozen_string_literal: true
# Posts (promotes into replies / "tags") any reply drafts whose scheduled time has
# arrived, like a Tumblr-style queue. Intended to be run periodically, e.g. via a
# scheduler / cron invoking `rake drafts:post_scheduled`.
class PostScheduledDraftsJob < ApplicationJob
  queue_as :high

  def perform
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
