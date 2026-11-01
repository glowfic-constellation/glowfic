# -*- encoding: utf-8 -*-
# stub: aws-actionmailer-ses 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "aws-actionmailer-ses".freeze
  s.version = "1.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/aws/aws-actionmailer-ses-ruby/blob/main/CHANGELOG.md", "documentation_uri" => "https://docs.aws.amazon.com/sdk-for-ruby/aws-actionmailer-ses/api/", "source_code_uri" => "https://github.com/aws/aws-actionmailer-ses-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amazon Web Services".freeze]
  s.date = "1980-01-02"
  s.description = "Amazon Simple Email Service as an ActionMailer delivery method".freeze
  s.email = ["aws-dr-rubygems@amazon.com".freeze]
  s.homepage = "https://github.com/aws/aws-actionmailer-ses-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "4.0.6".freeze
  s.summary = "ActionMailer integration with SES".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<aws-sdk-ses>.freeze, ["~> 1".freeze, ">= 1.50.0".freeze])
  s.add_runtime_dependency(%q<aws-sdk-sesv2>.freeze, ["~> 1".freeze, ">= 1.34.0".freeze])
  s.add_runtime_dependency(%q<actionmailer>.freeze, [">= 7.1.0".freeze])
end
