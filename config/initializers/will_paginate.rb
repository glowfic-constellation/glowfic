require 'will_paginate/view_helpers/action_view'
require 'will_paginate/view_helpers/link_renderer'

module WillPaginate
  class Collection
    def klass
      first.class
    end
  end

  module ActionView
    protected
    class LinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
      def container_attributes
        super.except(:first_label, :last_label, :summary_label, :mobile_view)
      end

      protected

      alias_method :_add_current_page_param, :add_current_page_param

      def add_current_page_param(url_params, page)
        # don't include a :page param at all if on the first page,
        # so that we properly show the links as visited.
        if page == 1
          url_params.delete(:page)
          return
        end

        _add_current_page_param(url_params, page)
      end

      def first_page
        num = @collection.current_page > 1 && 1
        previous_or_next_page(num, @options[:first_label], "first_page")
      end

      def last_page
        num = @collection.current_page < total_pages && @collection.total_pages
        previous_or_next_page(num, @options[:last_label], "last_page")
      end

      def summary
        tag(:span, @options[:summary_label] % [ current_page, @collection.total_pages ], class: "summary")
      end

      alias_method :_pagination, :pagination
      def pagination
        return _pagination unless @options[:mobile_view]
        [:first_page, :previous_page, :summary, :next_page, :last_page]
      end
    end
  end
end

WillPaginate.per_page = 25
