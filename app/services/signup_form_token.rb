# frozen_string_literal: true

# A signed timestamp embedded in the sign-up form. Together with a hidden honeypot field it
# lets the server reject sign-ups that were posted without loading the form, or faster than a
# person could fill it in. No third party and no JavaScript are involved.
module SignupFormToken
  MIN_AGE = 3.seconds
  MAX_AGE = 1.day
  PURPOSE = :signup_form

  def self.generate(issued: Time.current)
    verifier.generate(issued.to_i, purpose: PURPOSE)
  end

  def self.valid?(token, now: Time.current)
    return false if token.blank?
    issued_at = verifier.verified(token.to_s, purpose: PURPOSE)
    return false unless issued_at.is_a?(Integer)
    age = now.to_i - issued_at
    age.between?(MIN_AGE, MAX_AGE)
  end

  def self.verifier
    Rails.application.message_verifier(:signup_form)
  end
end
