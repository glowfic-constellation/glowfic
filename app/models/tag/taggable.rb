module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    before_save :save_tags

    def self.has_tags(**tag_types)
      class_eval do
        class_attribute :tag_types
        self.tag_types = tag_types

        attribute_method_prefix 'get_'

        def get_attribute(type_list)
          type = type_list[0..-6].to_s.pluralize
          Tag::List.new(send(type).map(&:name))
        end
      end

      tag_types.each_key do |type|
        type_list = "#{type}_list"

        class_eval do
          attribute type_list.to_sym, :string, array: true, default: []
          define_attribute_method(type_list)

          define_method(type_list) do
            list = read_attribute(type_list)
            return list if list.present?
            list = send("get_#{type_list}")
            write_attribute(type_list, list)
            list
          end

          define_method("#{type_list}=") do |list|
            list = Tag::List.new(list)
            return if list == send(type_list)
            set_attribute_was(type_list, send(type_list))
            write_attribute(type_list, list)
          end
        end
      end
    end

    def dirtify_tag_list(join)
      type = join.tag.type.tableize.singularize
      send("#{type}_list_will_change!")
    end

    def save_tags
      self.tag_types.each_key do |type|
        type_list = "#{type}_list"
        next unless attribute_changed?(type_list)
        new_list = changes[type_list][1]
        old_list = attribute_was(type_list) || []
        add_tags(type, new_list - old_list)
        rem_tags(type, old_list - new_list)
      end
    end

    def add_tags(type, list)
      return if list.blank?
      klass = self.tag_types[type]
      existing_tags = klass.where(name: list)
      new_tags = list - existing_tags.pluck(:name)
      list.each do |name|
        if new_tags.include?(name)
          tag = klass.create!(name: name, user: user)
        else
          tag = klass.find_by(name: name)
        end
        tag_join.new(tag: tag)
      end
    end

    def rem_tags(type, list)
      return if list.blank?
      tags = self.tag_types[type].where(name: list).pluck(:id)
      tag_join.where(tag_id: tags).destroy_all
    end

    def tag_join
      send(self.class.table_name.singularize+'_tags')
    end
  end
end
