# -*- encoding: utf-8 -*-
# stub: nilify_blanks 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "nilify_blanks".freeze
  s.version = "2.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubiety/nilify_blanks/issues", "changelog_uri" => "https://github.com/rubiety/nilify_blanks/blob/master/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rubiety/nilify_blanks" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben Hughes".freeze]
  s.date = "1980-01-02"
  s.description = "Often times you'll end up with empty strings where you really want nil at the database level.  This plugin automatically converts blanks to nil and is configurable.".freeze
  s.email = "me@benhughes.name".freeze
  s.homepage = "https://github.com/rubiety/nilify_blanks".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "Auto-convert blank fields to nil.".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.1".freeze])
end
