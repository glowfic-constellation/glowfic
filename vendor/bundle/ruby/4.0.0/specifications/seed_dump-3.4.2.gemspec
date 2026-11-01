# -*- encoding: utf-8 -*-
# stub: seed_dump 3.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "seed_dump".freeze
  s.version = "3.4.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rob Halff".freeze, "Ryan Oblak".freeze]
  s.date = "2026-05-13"
  s.description = "Dump (parts) of your database to db/seeds.rb to get a headstart creating a meaningful seeds.rb file".freeze
  s.email = "rroblak@gmail.com".freeze
  s.homepage = "https://github.com/rroblak/seed_dump".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.22".freeze
  s.summary = "Seed Dumper for Rails".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4".freeze])
  s.add_development_dependency(%q<byebug>.freeze, ["~> 11.1".freeze])
  s.add_development_dependency(%q<factory_bot>.freeze, ["~> 6.1".freeze])
  s.add_development_dependency(%q<activerecord-import>.freeze, ["~> 0.28".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13".freeze])
  s.add_development_dependency(%q<database_cleaner-active_record>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.4".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 1.3".freeze])
  s.add_development_dependency(%q<mutex_m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<logger>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<benchmark>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<base64>.freeze, [">= 0".freeze])
end
