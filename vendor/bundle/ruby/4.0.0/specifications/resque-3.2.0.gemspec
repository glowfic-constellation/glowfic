# -*- encoding: utf-8 -*-
# stub: resque 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "resque".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/resque/resque/blob/master/HISTORY.md", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Wanstrath".freeze, "Steve Klabnik".freeze, "Terence Lee".freeze, "Michael Bianco".freeze, "Patrick Tulskie".freeze]
  s.date = "1980-01-02"
  s.description = "    Resque is a Redis-backed Ruby library for creating background jobs,\n    placing those jobs on multiple queues, and processing them later.\n\n    Background jobs can be any Ruby class or module that responds to\n    perform. Your existing classes can easily be converted to background\n    jobs or you can create new classes specifically to do work. Or, you\n    can do both.\n\n    Resque is heavily inspired by DelayedJob (which rocks) and is\n    comprised of three parts:\n\n    * A Ruby library for creating, querying, and processing jobs\n    * A Rake task for starting a worker which processes jobs\n    * A Sinatra app for monitoring queues, jobs, and workers.\n".freeze
  s.email = ["steve@steveklabnik.com".freeze, "PatrickTulskie@gmail.com".freeze]
  s.executables = ["resque".freeze, "resque-web".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.markdown".freeze]
  s.files = ["LICENSE".freeze, "README.markdown".freeze, "bin/resque".freeze, "bin/resque-web".freeze]
  s.homepage = "https://github.com/resque/resque".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "4.0.16".freeze
  s.summary = "Resque is a Redis-backed queueing system.".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<base64>.freeze, ["~> 0.1".freeze])
  s.add_runtime_dependency(%q<logger>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<redis-namespace>.freeze, ["~> 1.6".freeze])
  s.add_runtime_dependency(%q<redis>.freeze, [">= 4.0".freeze])
  s.add_runtime_dependency(%q<sinatra>.freeze, [">= 2.0".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<mono_logger>.freeze, ["~> 1".freeze])
  s.add_development_dependency(%q<puma>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0".freeze])
end
