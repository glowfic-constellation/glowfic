# -*- encoding: utf-8 -*-
# stub: traceroute 0.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "traceroute".freeze
  s.version = "0.8.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akira Matsuda".freeze]
  s.date = "2020-04-28"
  s.description = "This Rake task investigates the application's routes definition, then tells you unused routes and unreachable action methods".freeze
  s.email = ["ronnie@dio.jp".freeze]
  s.extra_rdoc_files = ["README.rdoc".freeze]
  s.files = ["README.rdoc".freeze]
  s.homepage = "https://github.com/amatsuda/traceroute".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A Rake task that helps you find the dead routes and actions for your Rails 3 app".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 3.0.0".freeze])
end
