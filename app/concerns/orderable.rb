module Orderable
  extend ActiveSupport::Concern

  included do
    before_save :autofill_order
    after_save :reorder_others_after
    after_destroy :reorder_others_before

    def order=(val)
      self.send("#{self.class.order_column}=", val)
    end

    def self.order_column
      'section_order'
    end
    scope :ordered_manually, -> { order(self.order_column + ' asc') }

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

      sql_where = where_to_sql(other_where)
      sql = """
      WITH v_sections AS
      (
        SELECT ROW_NUMBER() OVER (
          PARTITION BY #{self.send(:ordered_attributes).join(', ')} ORDER BY #{self.class.order_column} ASC
        ) AS rn, id FROM #{self.class.table_name} WHERE #{sql_where}
      )
      UPDATE #{self.class.table_name}
      SET #{self.class.order_column} = v_sections.rn-1
      FROM v_sections
      WHERE #{self.class.table_name}.id = v_sections.id
      """
      sql += "AND #{sql_where};"
      self.class.connection.execute(sql)
    end

    def where_to_sql(where_hash)
      where_hash.map do |column, value|
        next "#{column} is NULL" unless value
        "#{column} = #{value}"
      end.join(' AND ')
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
