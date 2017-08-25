# Be sure to restart your server when you modify this file.

options = if Rails.env.production?
  {domain: ['glowfic.com', '.glowfic-staging.herokuapp.com'], tld_length: 2}
elsif Rails.env.development?
  {domain: 'localhost', tld_length: 2}
else
  {}
end

Rails.application.config.session_store :cookie_store, key: '_glowfic_constellation_' + Rails.env, **options
