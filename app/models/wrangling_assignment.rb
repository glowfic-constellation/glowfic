# frozen_string_literal: true
class WranglingAssignment < ApplicationRecord
  belongs_to :user, inverse_of: :wrangling_assignments, optional: false
  belongs_to :setting, inverse_of: :wrangling_assignments, optional: false

  validates :user_id, uniqueness: { scope: :setting_id }
  validate :setting_is_a_setting

  # Assigned settings plus everything below them in the implication graph.
  def self.scope_ids_for(user)
    return [] if user.nil?

    direct_ids = where(user_id: user.id).pluck(:setting_id)
    return [] if direct_ids.empty?

    descendants = Setting.where(id: direct_ids).flat_map(&:descendant_ids)
    (direct_ids + descendants).uniq
  end

  def self.reassign_for_merge(source:, target:)
    return if source.id == target.id

    losing = where(setting_id: source.id).to_a
    return if losing.empty?

    already_assigned = where(setting_id: target.id).pluck(:user_id).to_set

    transaction do
      losing.each do |assignment|
        if already_assigned.include?(assignment.user_id)
          assignment.destroy!
        else
          assignment.update!(setting: target)
        end
      end
    end

    notify_of_merge(losing.map(&:user_id) | already_assigned.to_a, source: source, target: target)
  end

  def self.notify_of_merge(user_ids, source:, target:)
    User.where(id: user_ids).find_each do |user|
      Notification.notify_user(
        user,
        :wrangling_scope_merged,
        error: "Setting #{source.name} was merged into #{target.name}. Your wrangling scope has changed.",
      )
    end
  end
  private_class_method :notify_of_merge

  private

  def setting_is_a_setting
    return if setting.nil?
    errors.add(:setting, "must be a setting") unless setting.is_a?(Setting)
  end
end
