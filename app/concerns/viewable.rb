# frozen_string_literal: true
module Viewable
  extend ActiveSupport::Concern

  included do
    def mark_read(user, at_time: nil, force: false, at_reply: nil)
      view = view_for(user)

      updates = {}
      if view.new_record? || at_time.blank?
        updates[:read_at] = at_time || Time.now.in_time_zone
      elsif force || view.read_at.nil? || at_time > view.read_at
        updates[:read_at] = at_time
      end
      updates[:last_read_reply_id] = at_reply.id if at_reply && (force || marker_advanced?(view, at_reply))

      return true if updates.empty?
      view.update(updates)
    end

    def ignore(user)
      view_for(user).update(ignored: true)
    end

    def unignore(user)
      view_for(user).update(ignored: false)
    end

    def ignored_by?(user)
      view_for(user).ignored
    end

    def last_read(user)
      view_for(user).read_at
    end

    def reload
      @view = nil
      @first_unread = nil
      super
    end

    private

    def view_for(user)
      @view ||= views.where(user_id: user.id).first_or_initialize
    end

    def marker_advanced?(view, at_reply)
      # Advance an unread reply marker if one doesn't exist, or if its order
      # is later than the current latest read reply's order
      return true if view.new_record? || view.last_read_reply_id.nil?
      return false if view.last_read_reply_id == at_reply.id
      current_order = replies.where(id: view.last_read_reply_id).pick(:reply_order)
      current_order.nil? || at_reply.reply_order > current_order
    end
  end
end
