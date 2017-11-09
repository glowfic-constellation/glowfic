module Taggable
  extend ActiveSupport::Concern

  included do
    def self.acts_as_tag(*tag_names)
      # for each tag name, create a getter and a custom setter for tag_name_ids, so that it updates the relevant association and stays up to date
      # will be outdated if you set the IDs then update the tag list directly without setting the IDs again
      # defaults to building new tags with `user`, but can be modified before saving with `build_new_tags_with`
      @acts_as_tags = tag_names
      tag_names.each do |tag_name|
        base = tag_name.to_s # setting, content_warning
        klass = base.camelize.constantize # Setting, ContentWarning
        tag_method = base + 's' # settings, content_warnings
        tag_method_assign = tag_method + '='
        tag_ids_method = base + '_ids' # setting_ids, content_warning_ids
        tag_ids_method_assign = tag_ids_method + '='
        attr_reader tag_ids_method
        # on assignment of tag IDs, find relevant tag objects and new-ify unfound ones, then set local variable:
        define_method(tag_ids_method_assign) do |tag_ids|
          tag_ids = tag_ids.uniq - ['']
          match_ids = tag_ids.map do |id|
            # map "_test" to "TEST"; 5 to 5; "5" to 5, for ease of matching order
            if id.to_s.start_with?('_')
              id.to_s.upcase[1..-1]
            elsif id.to_i.to_s == id.to_s
              id.to_i
            else
              id
            end
          end
          # fake tag IDs start with initial underscore
          fakes = tag_ids.select { |id| id.to_s.start_with?('_') }.uniq
          tag_ids -= fakes # remove them from proper list
          old_tags = klass.where(id: tag_ids)

          fakes.map! { |name| name[1..-1].strip } # trim names

          # find existing tags by same name
          existing_tags = klass.where(name: fakes)
          # remove fakes with same name, case-insensitively
          existing_names = (old_tags + existing_tags).map(&:name).map(&:upcase)
          fakes.reject! { |name| existing_names.include?(name.upcase) }

          # create real tags for remaining fakes, must be added user separately
          new_tags = fakes.map { |name| klass.new(user: user, name: name) }

          # set tag list to: [old tags] + [existing new tags] + [new tags]
          # sort by input order
          final_tags = (old_tags + existing_tags + new_tags).uniq
          final_tags.sort_by! do |x|
            type = match_ids.index(x.name.upcase) || match_ids.index(x.id)
            type
          end
          self.public_send(tag_method_assign, final_tags)
          self.instance_variable_set('@' + tag_ids_method, final_tags.map(&:id_for_select))
        end
      end
    end

    def build_new_tags_with(user)
      self.class.instance_variable_get(:@acts_as_tags).each do |tag_name|
        base = tag_name.to_s
        tag_method = base + 's'
        self.public_send(tag_method).each do |tag|
          next if tag.persisted?
          tag.user = user
        end
      end
    end
  end
end
