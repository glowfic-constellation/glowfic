# -*- encoding: utf-8 -*-
# stub: apipie-rails 1.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "apipie-rails".freeze
  s.version = "1.5.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/Apipie/apipie-rails/issues", "changelog_uri" => "https://github.com/Apipie/apipie-rails/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/Apipie/apipie-rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pavel Pokorny".freeze, "Ivan Necas".freeze]
  s.date = "2026-06-26"
  s.description = "Rails REST API documentation tool".freeze
  s.email = ["pajkycz@gmail.com".freeze, "inecas@redhat.com".freeze]
  s.homepage = "https://github.com/Apipie/apipie-rails".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.2.33".freeze
  s.summary = "Rails REST API documentation tool".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0".freeze])
  s.add_development_dependency(%q<maruku>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<RedCloth>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<json-schema>.freeze, ["~> 2.8".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop_challenger>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rspec_rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
end
