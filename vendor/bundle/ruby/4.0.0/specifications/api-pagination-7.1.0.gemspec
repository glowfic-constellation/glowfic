# -*- encoding: utf-8 -*-
# stub: api-pagination 7.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "api-pagination".freeze
  s.version = "7.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Celis".freeze]
  s.date = "1980-01-02"
  s.description = "Link header pagination for Rails and Grape APIs".freeze
  s.email = ["me@davidcel.is".freeze]
  s.homepage = "https://github.com/davidcelis/api-pagination".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new("> 2.7".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "Link header pagination for Rails and Grape APIs. Don't use the request body.".freeze

  s.installed_by_version = "4.0.20".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<kaminari>.freeze, ["~> 1.2".freeze, ">= 1.2.1".freeze])
  s.add_development_dependency(%q<pagy>.freeze, ["~> 43.3".freeze])
  s.add_development_dependency(%q<will_paginate>.freeze, ["~> 3.3".freeze, ">= 3.3.1".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10".freeze])
  s.add_development_dependency(%q<grape>.freeze, ["~> 1.6".freeze])
  s.add_development_dependency(%q<railties>.freeze, ["~> 7.0".freeze])
  s.add_development_dependency(%q<actionpack>.freeze, ["~> 7.0".freeze])
  s.add_development_dependency(%q<sequel>.freeze, ["~> 5.49".freeze])
  s.add_development_dependency(%q<activerecord-nulldb-adapter>.freeze, ["~> 0.9.0".freeze])
end
