# -*- encoding: utf-8 -*-
# stub: pg_search 2.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pg_search".freeze
  s.version = "2.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Grant Hutchins".freeze]
  s.date = "1980-01-02"
  s.description = "PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search".freeze
  s.email = ["gems@nertzy.com".freeze]
  s.homepage = "https://github.com/Casecommons/pg_search".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.3".freeze)
  s.rubygems_version = "4.0.20".freeze
  s.summary = "PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 8.0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 8.0".freeze])
end
