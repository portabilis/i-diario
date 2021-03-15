module Api
  module V2
    class BaseController < ApplicationController
      skip_before_action :authenticate_user!
      skip_before_action :configure_permitted_parameters
      skip_before_action :check_for_notifications
      before_action :api_authenticate_with_header!
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response

      private

      def set_thread_origin_type
        Thread.current[:origin_type] = OriginTypes::API_V2
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

      def render_not_found_response
        render json: { message: 'Elemento não encontrado' },
               status: :not_found
      end

      def api_authenticate_with_header!
        return if allowed_api_header?

        authenticate_api!
      end

      def authenticate_api!
        api_security_token = IeducarApiConfiguration.current.api_security_token

        return if Devise.secure_compare(api_security_token, request.headers['token'])

        render_invalid_token
      end

      def ieducar_api
        @ieducar_api ||= IeducarApiConfiguration.current
      end
    end
  end
end
