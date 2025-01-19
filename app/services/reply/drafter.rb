# frozen_string_literal: true
class Reply::Drafter < Object
  def initialize(params, user:, char_params: {})
    if (@draft = ReplyDraft.draft_for(params[:post_id], user.id))
      @draft.assign_attributes(params)
    else
      @draft = ReplyDraft.new(params)
      @draft.user = user
    end
    @draft = Character::NpcCreater.new(@draft, char_params).process
  end

  def make_draft(show_message=true)
    new_npc = !@draft.character.nil? && !@draft.character.persisted?

    begin
      @draft.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(draft, action: 'saved', class_name: 'Draft', err: e)
    else
      if show_message
        msg = "Draft saved."
        msg += " Your new NPC character has also been persisted!" if new_npc
        flash[:success] = msg
      end
    end
  end
end
