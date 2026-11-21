# frozen_string_literal: true

# Keep specs fast; production and development use bcrypt's default cost.
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST if Rails.env.test?
