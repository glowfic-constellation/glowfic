# frozen_string_literal: true
namespace :skins do
  desc 'Seed the bundled layouts as pre-approved, forkable public skins'
  task seed_builtin: :environment do
    created = Glowfic::BuiltinSkins.seed!(logger: ->(msg) { puts msg })
    puts "Done. Created #{created} built-in skin(s)."
  rescue StandardError => e
    # Runs in the deploy release phase; a cosmetic seed failure should never
    # block a deploy. Surface it loudly in the logs and carry on.
    warn "skins:seed_builtin failed (continuing): #{e.class}: #{e.message}"
  end
end
