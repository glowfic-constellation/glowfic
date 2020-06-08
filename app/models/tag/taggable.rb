module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    def dirtify_tag_list(join)
      send("reload_#{join.tag.type}_list")
    end

    def save_tags(type, new_list:, old_list:, assoc:, join: tag_join)
      return if old_list == new_list
      add_tags(type, new_list - old_list, assoc)
      rem_tags(type, old_list - new_list, join)
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

    def rem_tags(type, list, join)
      tags = type.where(name: list).pluck(:id)
      join.where(tag_id: tags).destroy_all
    end

    def tag_join
      send(self.class.table_name.singularize+'_tags')
    end
  end
end
