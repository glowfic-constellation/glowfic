module Tag::Taggable
  extend ActiveSupport::Concern

  included do
    private

    def dirtify_tag_list(join)
      attribute_will_change!(join.tag.type+"_list")
    end
  end
end
