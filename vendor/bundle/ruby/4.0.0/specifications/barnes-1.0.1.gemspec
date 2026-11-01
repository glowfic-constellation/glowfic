# -*- encoding: utf-8 -*-
# stub: barnes 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "barnes".freeze
  s.version = "1.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["schneems".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "Collect Ruby GC, ObjectSpace, and Puma metrics and report them directly to Heroku Runtime Metrics via HTTP.".freeze
  s.email = ["richard.schneeman@gmail.com".freeze]
  s.homepage = "https://github.com/heroku/barnes".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Report Ruby runtime metrics to Heroku".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<json>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<logger>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<ostruct>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack>.freeze, ["~> 2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3".freeze])
  s.add_development_dependency(%q<puma>.freeze, ["~> 5.6".freeze])
  s.add_development_dependency(%q<wait_for_it>.freeze, ["~> 0.1".freeze])
end
