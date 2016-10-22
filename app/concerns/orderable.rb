module Orderable
  extend ActiveSupport::Concern

  included do
    before_save :autofill_order
    after_save :reorder_others
    after_destroy :reorder_others

    private

    def reorder_others
      return unless destroyed? || order_change?

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
      self.section_order = ordered_for.ordered_items.count
    end

    def order_change?
      ordered_attributes.any? { |atr| send("#{atr}_changed?") }
    end

    def ordered_for
      id = ordered_attributes.detect { |a| send(a).present? }
      send(id.to_s[0..-4])
    end
  end
end
