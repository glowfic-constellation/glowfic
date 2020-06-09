module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    @tag_types = {}

    def self.has_tags(**tag_types)
      @tag_types = tag_types

      tag_types.each_key do |type|
        type_list = "#{type}_list"

        attr_reader("#{type_list}_was".to_sym)

        after_save("save_#{type}_tags".to_sym)

        define_method(type_list.to_sym) do
          return instance_variable_get("@#{type_list}") if instance_variable_defined?("@#{type_list}")
          list = send("get_#{type}_tags")
          instance_variable_set("@#{type_list}", list)
          list
        end

        define_method("#{type_list}=".to_sym) do |list|
          list = Tag::List.new(list)
          return if list == send(type_list)
          instance_variable_set("@#{type_list}_changed", true)
          instance_variable_set("@#{type_list}_was", send(type_list))
          instance_variable_set("@#{type_list}", list)
        end

        define_method("#{type_list}_changed?") do
          instance_variable_get("@#{type_list}_changed") == true
        end

        define_method("reload_#{type}_tags".to_sym) do
          instance_variable_set("@#{type_list}", send("get_#{type}_tags"))
        end

        define_method("get_#{type}_tags".to_sym) do
          Tag::List.new(send(type.to_s.pluralize).map(&:name))
        end

        define_method("save_#{type}_tags".to_sym) do
          return unless send("#{type_list}_changed?")
          save_tags(type)
        end
      end
    end

    def dirtify_tag_list(join)
      send("reload_#{join.tag.type}_list")
    end

    def save_tags(type)
      new_list = send("#{type}_list")
      old_list = send("#{type}_list_was")
      add_tags(type, new_list - old_list)
      rem_tags(type, old_list - new_list)
    end

    def add_tags(type, list)
      existing_tags = @tag_types[type].where(name: list)
      new_tags = list - existing_tags.pluck(:name)
      association = send(type.to_s.pluralize)
      list.each do |name|
        if new_tags.include?(name)
          association.create!(name: name, user: user)
        else
          association << type.find_by(name: name)
        end
      end
    end

    def rem_tags(type, list)
      tags = @tag_types[type].where(name: list).pluck(:id)
      tag_join.where(tag_id: tags).destroy_all
    end

    def tag_join
      send(self.class.table_name.singularize+'_tags')
    end
  end
end
