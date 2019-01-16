class Post::Saver < Auditable::Saver
  include Taggable

  attr_reader :post

  def initialize(post, user:, params:)
    @post = post
    super
    @settings = process_tags(Setting, :post, :setting_ids)
    @warnings = process_tags(ContentWarning, :post, :content_warning_ids)
    @labels = process_tags(Label, :post, :label_ids)
  end

  def update!
    @post.board ||= Board.find(3)
    super
  end

  private

  def check_audit_comment
    raise NoModNoteError if @user != @post.user && !@post.author_ids.include?(@user.id) && @post.audit_comment.blank?
    @post.audit_comment = nil if @post.changes.empty? # don't save an audit for a note and no changes
  end

  def permitted_params(include_associations=true)
    allowed_params = [
      :board_id,
      :section_id,
      :privacy,
      :subject,
      :description,
      :content,
      :character_id,
      :icon_id,
      :character_alias_id,
      :authors_locked,
      :audit_comment
    ]

    # prevents us from setting (and saving) associations on preview()
    if include_associations
      allowed_params << {
        unjoined_author_ids: [],
        viewer_ids: []
      }
    end

    @params.fetch(:post, {}).permit(allowed_params)
  end
end
