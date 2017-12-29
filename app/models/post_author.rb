class PostAuthor < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false
  belongs_to :invited_by, class_name: User, optional: true

  validates :user_id, uniqueness: { scope: :post_id }

  def build_invited_by(other)
    return if user_id == other.id
    self.invited_at = Time.now
    self.invited_by = other
  end

  def invite_by!(other)
    # return false if can_owe? && !updated_at.nil?
    update_attributes!(can_owe: true)
    return true if other.id == user_id
    return true if joined?
    update_attributes!(invited_at: Time.now, invited_by: other)
  end

  def uninvite!
    if joined?
      update_attributes!(can_owe: false, invited_at: nil, invited_by: nil)
    else
      # no longer relevantly a post author (can't owe, hasn't joined), so destroy
      destroy!
      destroyed?
    end
  end

  def opt_out_of_owed!
    update_attributes!(can_owe: false)
  end
end
