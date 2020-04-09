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

      def can_show?(feature)
        cache_key = [
          'MenuRender#can_show?',
          ActiveRecord::Base.connection.pool.spec.config[:database],
          current_user.admin?,
          current_user.current_user_role.try(:role),
          feature
        ]

        Rails.cache.fetch cache_key do
          policy(feature).index?
        end
      end

      def policy(feature)
        klass = begin
                  feature.singularize.camelcase.constantize
                rescue
                  feature
                end

        ApplicationPolicy.new(current_user, klass)
      end
    end
  end
end
