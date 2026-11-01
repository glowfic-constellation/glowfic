# -*- encoding: utf-8 -*-
# stub: haml 7.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "haml".freeze
  s.version = "7.5.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/haml/haml/issues", "changelog_uri" => "https://github.com/haml/haml/blob/main/CHANGELOG.md", "homepage_uri" => "https://haml.info/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/haml/haml" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Natalie Weizenbaum".freeze, "Hampton Catlin".freeze, "Norman Clarke".freeze, "Akira Matsuda".freeze, "Takashi Kokubun".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "An elegant, structured (X)HTML/XML templating engine.".freeze
  s.email = ["haml@googlegroups.com".freeze, "ronnie@dio.jp".freeze]
  s.executables = ["haml".freeze]
  s.files = ["exe/haml".freeze]
  s.homepage = "https://haml.info".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "An elegant, structured (X)HTML/XML templating engine.".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<prism>.freeze, [">= 1.1.0".freeze])
  s.add_runtime_dependency(%q<temple>.freeze, [">= 0.8.2".freeze])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<benchmark_driver>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<coffee-script>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<erubi>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<less>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 4.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sass>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<slim>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<string_template>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<unindent>.freeze, [">= 0".freeze])
end
