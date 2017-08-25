# Be sure to restart your server when you modify this file.

options = if Rails.env.production?
  {domain: ['.glowfic.com', '.glowfic-staging.herokuapp.com']}
elsif Rails.env.development?
  {domain: '.localhost'}
else
  {}
end

Rails.application.config.session_store :cookie_store, key: '_glowfic_constellation_' + Rails.env, **options
