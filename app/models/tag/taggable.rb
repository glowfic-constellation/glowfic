module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    def dirtify_tag_list(join)
      attribute_will_change!(join.tag.type+"_list")
    end

    def save_tags(type, new_list, old_list)
      return if old_list == new_list
      add_tags(type, new_list - old_list)
      rem_tags(type, old_list - new_list)
    end

    def add_tags(type, list)
      existing_tags = type.where(name: list)
      new_tags = list - existing_tags.pluck(:name)
      list.each do |name|
        if new_tags.include?(name)
          class_association(type).create!(name: name, user: user)
        else
          class_association(type) << type.find_by(name: name)
        end
      end
    end

    def rem_tags(type, list)
      tags = type.where(name: list)
      send(self.class.table_name.singularize+'_tags').where(tag: tags).destroy_all
    end

    def class_association(type)
      send(type.to_s.tableize)
    end
  end
end
