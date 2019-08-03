class Auditable::Saver < Generic::Saver
  def update
    build
    return false unless check_audit_comment
    save
  end

  def check_audit_comment
    if @user != @model.user && @model.audit_comment.blank?
      @errors.add(:audit_comment, :blank)
      @error_message = "You must provide a reason for your moderator edit."
      return false
    end
    @model.audit_comment = nil if @model.changes.empty? # don't save an audit for a note and no changes
    true
  end
end
