# frozen_string_literal: true
namespace :replies do
  desc "Backfill rendered_content for replies, newest first. BACKFILL_SLEEP sets the pause between batches."
  task backfill_rendered_content: :environment do
    scope = Reply.where('rendered_content_version IS DISTINCT FROM ?', Reply::RENDER_VERSION)
    pause = ENV.fetch('BACKFILL_SLEEP', '0.2').to_f
    total = scope.count
    puts "Backfilling rendered_content for #{total} replies"

    done = 0
    scope.select(:id, :content, :editor_mode).in_batches(of: 500, order: :desc) do |batch|
      batch.each do |reply|
        Reply.where(id: reply.id).update_all( # rubocop:disable Rails/SkipsModelValidations
          rendered_content: Reply.render_content(reply.content, reply.editor_mode),
          rendered_content_version: Reply::RENDER_VERSION,
        )
      end
      done += batch.size
      puts "  #{done} / #{total}" if (done % 10_000).zero?
      sleep pause
    end
    puts "Done."
  end
end
