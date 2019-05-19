class Auditable::Saver < Generic::Saver
  def update!
    build
    check_audit_comment
    save!
  end

  def check_audit_comment
    raise NoModNoteError if @user != @model.user && @model.audit_comment.blank?
    @model.audit_comment = nil if @model.changes.empty? # don't save an audit for a note and no changes
  end
end
