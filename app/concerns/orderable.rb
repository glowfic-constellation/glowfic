module Orderable
  extend ActiveSupport::Concern

  included do
    before_save :autofill_order
    after_save :reorder_others_after
    after_destroy :reorder_others_before

    scope :ordered_manually, -> { order('section_order asc') }

    def order
      section_order
    end

    def order=(val)
      self.section_order = val
    end

    private

    def reorder_others(is_after)
      return unless destroyed? || order_change?(is_after)

      if has_attribute?(:board_id) # all indexes are ordered
        board_checking_id = is_after ? board_id_before_last_save : board_id_was
        board_checking = Board.find_by_id(board_checking_id) || board
        return unless board_checking.ordered?
      end

      other_where = Hash[ordered_attributes.map do |atr|
        [atr, send(is_after ? "#{atr}_before_last_save" : "#{atr}_was")]
      end]
      others = self.class.where(other_where).ordered_manually
      return unless others.present?

      others.each_with_index do |other, index|
        next if other.order == index
        other.order = index
        other.save!
      end
    end

    def reorder_others_after
      reorder_others(true)
    end

    def reorder_others_before
      reorder_others(false)
    end

    def autofill_order
      return unless new_record? || order_change?(false)
      self.order = ordered_items.count
    end

    def order_change?(is_after)
      return if new_record? # otherwise we will reorder on create
      ordered_attributes.any? do |atr|
        method = is_after ? "saved_change_to_#{atr}?" : "#{atr}_changed?"
        send(method)
      end
    end

    def ordered_items
      id = ordered_attributes.detect { |a| send(a).present? }
      ordered_for = send(id.to_s[0..-4])
      where_attr = Hash[ordered_attributes.map { |a| [a, send(a)] }]
      ordered_for.send(self.class.to_s.tableize).where(where_attr)
    end
  end
end
