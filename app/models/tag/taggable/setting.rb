module Tag::Taggable::Setting
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    define_attribute_method :setting_list

    after_initialize :load_setting_tags
    after_save :save_setting_tags

    def setting_list
      @setting_list
    end

    def setting_list=(list)
      list = Tag::List.new(list)
      setting_list_will_change! unless list == setting_list
      @setting_list = list
    end

    private

    def load_setting_tags
      @setting_list = Tag::List.new(settings.map(&:name))
    end

    def save_setting_tags
      return unless setting_list_changed?
      save_tags(::Setting, @setting_list, setting_list_was)
    end
  end
end
