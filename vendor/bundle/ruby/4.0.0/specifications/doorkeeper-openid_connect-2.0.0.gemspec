# -*- encoding: utf-8 -*-
# stub: doorkeeper-openid_connect 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "doorkeeper-openid_connect".freeze
  s.version = "2.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/doorkeeper-gem/doorkeeper-openid_connect/issues", "changelog_uri" => "https://github.com/doorkeeper-gem/doorkeeper-openid_connect/blob/master/CHANGELOG.md", "funding_uri" => "https://opencollective.com/doorkeeper-gem", "homepage_uri" => "https://github.com/doorkeeper-gem/doorkeeper-openid_connect", "source_code_uri" => "https://github.com/doorkeeper-gem/doorkeeper-openid_connect" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sam Dengler".freeze, "Markus Koller".freeze, "Nikita Bulai".freeze]
  s.date = "2026-09-22"
  s.description = "OpenID Connect extension for Doorkeeper.".freeze
  s.email = ["sam.dengler@playonsports.com".freeze, "markus-koller@gmx.ch".freeze, "bulajnikita@gmail.com".freeze]
  s.homepage = "https://github.com/doorkeeper-gem/doorkeeper-openid_connect".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "OpenID Connect extension for Doorkeeper.".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<doorkeeper>.freeze, [">= 5.5".freeze, "< 7.0".freeze])
  s.add_runtime_dependency(%q<jwt>.freeze, [">= 2.5".freeze])
  s.add_runtime_dependency(%q<ostruct>.freeze, [">= 0.5".freeze])
  s.add_development_dependency(%q<bigdecimal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<conventional-changelog>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<drb>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<factory_bot>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mutex_m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 1.3.6".freeze])
end
