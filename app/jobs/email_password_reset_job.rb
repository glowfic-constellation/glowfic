class EmailPasswordResetJob < BaseJob
  @queue = :email

  def self.process(password_reset_id)
    Rails.logger.info("[EmailPasswordResetJob] sending reset #{password_reset_id}")
    return unless password_reset = PasswordReset.find_by_id(password_reset_id)
    UserMailer.password_reset_link(password_reset).deliver
  end
end
