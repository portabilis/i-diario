module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :authenticate_user!
      skip_before_action :configure_permitted_parameters
      skip_before_action :check_for_notifications
      before_action :api_authenticate_with_header!

      private

      def set_thread_origin_type
        Thread.current[:origin_type] = OriginTypes::API_V1
        begin
          yield
        ensure
          Thread.current[:origin_type] = nil
        end
      end

      def render_invalid_token
        render json: { errors: 'Token inválido' },
               status: :unauthorized
      end

      def api_authenticate_with_header!
        header_name1 = Rails.application.secrets[:AUTH_HEADER_NAME1] || 'TOKEN'
        validation_method1 = Rails.application.secrets[:AUTH_VALIDATION_METHOD1] || '=='
        token1 = Rails.application.secrets[:AUTH_TOKEN1]

        header_name2 = Rails.application.secrets[:AUTH_HEADER_NAME2] || 'TOKEN'
        validation_method2 = Rails.application.secrets[:AUTH_VALIDATION_METHOD2] || '=='
        token2 = Rails.application.secrets[:AUTH_TOKEN2]

        if request.headers[header_name1].send(validation_method1, token1) ||
            token2.present? && request.headers[header_name2].send(validation_method2, token2)
          return
        end

        render_invalid_token
      end

      def authenticate_api!
        render_invalid_token unless ieducar_api.authenticate!(params[:token])
      end

      def ieducar_api
        @ieducar_api ||= IeducarApiConfiguration.current
      end
    end
  end
end
