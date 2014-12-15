module Navigation
  module Render
    class Base
      def initialize(user, helpers = ::ApplicationController.helpers, routes = ::Rails.application.routes.url_helpers)
        @current_user = user
        @routes = routes
        @helpers = helpers
      end

      def path_method(method)
        return "#" unless method

        routes.send(method)
      end

      protected

      attr_reader :current_user, :routes, :helpers

      delegate :raw, :content_tag, :link_to, :to => :helpers
    end
  end
end
