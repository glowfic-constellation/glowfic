# -*- encoding: utf-8 -*-
# stub: exception_notification 5.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "exception_notification".freeze
  s.version = "5.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/kmcphillips/exception_notification/blob/master/CHANGELOG.rdoc" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamis Buck".freeze, "Josh Peek".freeze, "Sebasti\u00E1n Mart\u00EDnez".freeze, "Kevin McPhillips".freeze]
  s.date = "2025-08-03"
  s.email = "github@kevinmcphillips.ca".freeze
  s.homepage = "https://kmcphillips.github.io/exception_notification/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "Exception notification for Ruby applications".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionmailer>.freeze, [">= 7.1".freeze, "< 9".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 7.1".freeze, "< 9".freeze])
  s.add_development_dependency(%q<aws-sdk-sns>.freeze, ["~> 1".freeze])
  s.add_development_dependency(%q<carrier-pigeon>.freeze, [">= 0.7.0".freeze])
  s.add_development_dependency(%q<dogapi>.freeze, [">= 1.23.0".freeze])
  s.add_development_dependency(%q<hipchat>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<httparty>.freeze, ["~> 0.10.2".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0.13.0".freeze])
  s.add_development_dependency(%q<mock_redis>.freeze, ["~> 0.19.0".freeze])
  s.add_development_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<ostruct>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 7.1".freeze, "< 9".freeze])
  s.add_development_dependency(%q<resque>.freeze, ["~> 1.8.0".freeze])
  s.add_development_dependency(%q<sidekiq>.freeze, [">= 5.0.4".freeze])
  s.add_development_dependency(%q<slack-notifier>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9.0".freeze])
end
