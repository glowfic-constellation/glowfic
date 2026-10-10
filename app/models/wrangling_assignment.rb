# frozen_string_literal: true
class WranglingAssignment < ApplicationRecord
  belongs_to :user, inverse_of: :wrangling_assignments, optional: false
  belongs_to :setting, inverse_of: :wrangling_assignments, optional: false

  validates :user_id, uniqueness: { scope: :setting_id }

  # Assigned Settings plus everything below them in the implication graph.
  def self.scope_ids_for(user)
    return [] if user.nil?
    Tag::MetaTag.self_and_descendant_ids(where(user_id: user.id).pluck(:setting_id))
  end

  # Moves assignments from a merged-away Setting onto the survivor and notifies
  # every wrangler of either, since all of their scopes have changed.
  def self.reassign_for_merge(source:, target:)
    losing = where(setting_id: source.id).to_a
    return if losing.empty?

    already_assigned = where(setting_id: target.id).pluck(:user_id)
    losing.each do |assignment|
      if already_assigned.include?(assignment.user_id)
        assignment.destroy!
      else
        assignment.update!(setting: target)
      end
    end

    User.where(id: losing.map(&:user_id) | already_assigned).find_each do |user|
      Notification.notify_user(
        user,
        :wrangling_scope_merged,
        error: "Setting #{source.name} was merged into #{target.name}. Your wrangling scope has changed.",
      )
    end
  end
end
