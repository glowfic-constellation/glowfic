module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    after_save :save_tags

    def self.has_tags(**tag_types)
      class_eval do
        class_attribute :tag_types
        self.tag_types = tag_types
      end

      tag_types.each_key do |type|
        type_list = "#{type}_list"

        class_eval { attribute type_list.to_sym, :string, array: true }

        define_method(type_list.to_sym) do
          return instance_variable_get("@#{type_list}") if instance_variable_defined?("@#{type_list}")
          list = send("get_#{type}_tags")
          instance_variable_set("@#{type_list}", list)
          list
        end

        define_method("#{type_list}=".to_sym) do |list|
          list = Tag::List.new(list)
          return if list == send(type_list)
          attribute_will_change!(type_list)
          instance_variable_set("@#{type_list}", list)
        end

        define_method("get_#{type}_tags".to_sym) do
          Tag::List.new(send(type.to_s.pluralize).map(&:name))
        end
      end
    end

    def dirtify_tag_list(join)
      type = join.tag.type.tableize.singularize
      send("#{type}_list=", send("get_#{type}_tags"))
    end

    def save_tags
      self.tag_types.each_key do |type|
        type_list = "#{type}_list"
        next unless attribute_changed?(type_list)
        new_list = send(type_list)
        old_list = attribute_was(type_list) || []
        add_tags(type, new_list - old_list)
        rem_tags(type, old_list - new_list)
        changes_applied
      end
    end

    def add_tags(type, list)
      return if list.blank?
      klass = self.tag_types[type]
      existing_tags = klass.where(name: list)
      new_tags = list - existing_tags.pluck(:name)
      association = send(type.to_s.pluralize)
      list.each do |name|
        if new_tags.include?(name)
          association.create!(name: name, user: user)
        else
          tag_join.create!(tag: klass.find_by(name: name))
        end
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
