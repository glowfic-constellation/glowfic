class AboutController < ApplicationController
  def tos
    @page_title = 'Terms of Service'
  end

  def privacy
    @page_title = 'Privacy Policy'
  end

  def contact
    @page_title = 'Contact Us'
  end

  def dmca
    @page_title = 'DMCA Policy'
  end
end
