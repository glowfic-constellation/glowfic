# frozen_string_literal: true
namespace :drafts do
  desc "Post scheduled reply drafts whose time has come (run periodically via cron/scheduler)"
  task post_scheduled: :environment do
    PostScheduledDraftsJob.perform_now
  end
end
