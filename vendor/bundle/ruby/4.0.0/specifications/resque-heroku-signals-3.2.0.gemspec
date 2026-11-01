# -*- encoding: utf-8 -*-
# stub: resque-heroku-signals 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "resque-heroku-signals".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bianco".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.email = ["mike@mikebian.co".freeze]
  s.homepage = "https://github.com/resque/resque-heroku-signals".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "4.0.16".freeze
  s.summary = "Patch resque to be compatible with Heroku".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<resque>.freeze, ["= 3.2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10".freeze])
end
