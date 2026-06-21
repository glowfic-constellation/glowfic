# frozen_string_literal: true
namespace :skins do
  desc 'Seed the bundled layouts as pre-approved, forkable public skins'
  task seed_builtin: :environment do
    created = Glowfic::BuiltinSkins.seed!(logger: ->(msg) { puts msg })
    puts "Done. Created #{created} built-in skin(s)."
  end
end
