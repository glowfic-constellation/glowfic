module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    def dirtify_tag_list(join)
      send("reload_#{join.tag.type}_list")
    end

    def save_tags(type, new_list:, old_list:, assoc:)
      return if old_list == new_list
      add_tags(type, new_list - old_list, assoc)
      rem_tags(type, old_list - new_list)
    end

    def add_tags(type, list, assoc)
      existing_tags = type.where(name: list)
      new_tags = list - existing_tags.pluck(:name)
      list.each do |name|
        if new_tags.include?(name)
          assoc.create!(name: name, user: user)
        else
          assoc << type.find_by(name: name)
        end
      end
    end

    def rem_tags(type, list)
      tags = type.where(name: list)
      send(self.class.table_name.singularize+'_tags').where(tag: tags).destroy_all
    end
  end
end
