module ContextHelper
  def context
    Context.new
  end

  class Context
    include ActionView::Helpers::OutputSafetyHelper # method raw
    include ActionView::Helpers::TagHelper # method content_tag
    include ActionView::Helpers::UrlHelper # method link_to

    attr_accessor :output_buffer

    def method_missing(method, *args, &block)
      if "#{method}" =~ /_path$/
        Rails.application.routes.url_helpers.send(method)
      end
    end
  end
end

RSpec.configure do |config|
  config.include ContextHelper, type: :service
end
