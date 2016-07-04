module WillPaginate
  module ActionView
    protected
    class LinkRenderer < ViewHelpers::LinkRenderer
      protected
      def add_current_page_param(url_params, page)
        # don't include a :page param at all if on the first page,
        # so that we properly show the links as visited.
        if page == 1
          url_params.delete(:page)
          return
        end

        super(url_params, page)
      end
    end
  end
end

