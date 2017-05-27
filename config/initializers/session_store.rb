# Be sure to restart your server when you modify this file.

options = {}#Rails.env.production? ? {domain: 'glowfic.com', tld_length: 2} : {}
Rails.application.config.session_store :cookie_store, key: '_glowfic_session', **options
