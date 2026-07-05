# frozen_string_literal: true

namespace :replies do
  desc "Backfill the cached word_count column on replies that don't yet have one"
  task backfill_word_count: :environment do
    scope = Reply.where(word_count: nil)
    total = scope.count
    puts "Backfilling word_count for #{total} replies"

    sanitizer = Rails::Html::FullSanitizer.new
    done = 0
    scope.select(:id, :content).find_in_batches(batch_size: 1000) do |batch|
      batch.each do |reply|
        words = reply.content.nil? ? 0 : sanitizer.sanitize(reply.content).split.size
        Reply.where(id: reply.id).update_all(word_count: words) # rubocop:disable Rails/SkipsModelValidations
      end
      done += batch.size
      puts "  #{done} / #{total}"
    end
    puts "Done."
  end
end
