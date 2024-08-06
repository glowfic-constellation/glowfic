# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Rails::Conductor::BaseController`.
# Please instead update this file by running `bin/tapioca dsl Rails::Conductor::BaseController`.


class Rails::Conductor::BaseController
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule

  sig { returns(HelperProxy) }
  def helpers; end

  module HelperMethods
    include ::ActionText::ContentHelper
    include ::ActionText::TagHelper
    include ::ActionController::Base::HelperMethods
    include ::ApplicationHelper
    include ::CharacterHelper
    include ::IconHelper
    include ::MailerHelper
    include ::PostHelper
    include ::ReportsHelper
    include ::TagHelper
    include ::WritableHelper
    include ::ActionView::Helpers::CaptureHelper
    include ::ActionView::Helpers::OutputSafetyHelper
    include ::ActionView::Helpers::TagHelper
    include ::ApipieHelper
  end

  class HelperProxy < ::ActionView::Base
    include HelperMethods
  end
end
