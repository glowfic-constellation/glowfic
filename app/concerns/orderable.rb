module Orderable
  extend ActiveSupport::Concern

  included do
    before_save :autofill_order
    after_save :reorder_others
    after_destroy :reorder_others

    private

    def reorder_others
      return unless destroyed? || order_change?

      if has_attribute?(:board_id) # all indexes are ordered
        board_checking = Board.find_by_id(board_id_was) || board
        return unless board_checking.ordered?
      end

      other_where = Hash[ordered_attributes.map { |atr| [atr, send("#{atr}_was")] }]
      others = self.class.where(other_where).order('section_order asc')
      return unless others.present?

      others.each_with_index do |other, index|
        next if other.section_order == index
        other.section_order = index
        other.save
      end
    end

    def autofill_order
      return unless new_record? || order_change?
      self.section_order = ordered_items.count
    end

    def order_change?
      return if new_record? # otherwise we will reorder on create
      ordered_attributes.any? { |atr| send("#{atr}_changed?") }
    end

    def ordered_items
      id = ordered_attributes.detect { |a| send(a).present? }
      ordered_for = send(id.to_s[0..-4])
      where_attr = Hash[ordered_attributes.map { |a| [a, send(a)] }]
      ordered_for.send(self.class.to_s.tableize).where(where_attr)
    end
  end
end
