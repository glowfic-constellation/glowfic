# frozen_string_literal: true
class Reply::Drafter < Object
  def initialize
    if (@draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id))
      @draft.assign_attributes(permitted_params)
    else
      @draft = ReplyDraft.new(permitted_params)
      @draft.user = current_user
    end
  end

  def make_draft(show_message=true)
    process_npc(draft, permitted_character_params)
    new_npc = !draft.character.nil? && !draft.character.persisted?

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
