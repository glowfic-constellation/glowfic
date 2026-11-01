# frozen_string_literal: true

require "rails/generators/erb/authentication/authentication_generator"

module Haml
  module Generators
    class AuthenticationGenerator < Erb::Generators::AuthenticationGenerator
      source_root File.expand_path("../templates", __FILE__)

      def create_files
        template "app/views/passwords/new.html.haml"
        template "app/views/passwords/edit.html.haml"
        template "app/views/sessions/new.html.haml"
      end
    end
  end
end
