# -*- encoding: utf-8 -*-
# stub: rack-pratchett 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-pratchett".freeze
  s.version = "0.1.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rob".freeze]
  s.bindir = "exe".freeze
  s.date = "2015-03-15"
  s.description = "Includes {'X-Clacks-Overhead': 'GNU Terry Pratchett'} header inside any rack application. http://redd.it/2yt9j6".freeze
  s.email = ["root@sphericalcube.net".freeze]
  s.homepage = "https://github.com/wonderbread/rack-pratchett".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.4.5".freeze
  s.summary = "Terry Pratchett rack middleware. GNU Terry Pratchett.".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.8".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack>.freeze, [">= 0".freeze])
end
