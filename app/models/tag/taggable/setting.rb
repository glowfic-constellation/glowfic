module Tag::Taggable::Setting
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    attr_reader :setting_list, :setting_list_was, :setting_list_changed
    alias_method :setting_list_changed?, :setting_list_changed

    after_initialize :load_setting_tags
    after_save :save_setting_tags

    def setting_list=(list)
      list = Tag::List.new(list)
      return if list == setting_list
      @setting_list_changed = true
      @setting_list_was = @setting_list
      @setting_list = list
    end

    private

    def load_setting_tags
      @setting_list = get_setting_tags
    end

    def reload_setting_tags
      self.setting_list=get_setting_tags
    end

    def get_setting_tags
      Tag::List.new(settings.map(&:name))
    end

    def save_setting_tags
      return unless setting_list_changed?
      save_tags(::Setting, new_list: @setting_list, old_list: setting_list_was, assoc: settings)
    end
  end
end
