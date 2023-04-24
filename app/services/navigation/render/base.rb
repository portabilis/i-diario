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
        # rubocop:todo Entender como melhorar esta questão das entidades nos testes
        entity_id = Rails.env.test? ? '1' : Entity.current.id

        cache_key = [
          'MenuRender#can_show?',
          entity_id,
          current_user.admin?,
          current_user.current_user_role&.role&.cache_key || current_user.cache_key,
          feature
        ]

        Rails.cache.fetch cache_key, expires_in: 1.day do
          policy(feature).index?
        end
      end

      def policy(feature)
        klass = begin
                  feature.singularize.camelcase.constantize
                rescue
                  feature
                end

        begin
          result = Pundit::PolicyFinder.new(klass).policy!.new(current_user, klass)
          Rails.logger.info 'LOG: Navigation::Render::Base#policy - Policy found'
          result
        rescue
          result = ApplicationPolicy.new(current_user, klass)
          Rails.logger.info 'LOG: Navigation::Render::Base#policy - Policy fallback'
          result
        end
      end
    end
  end
end
