module Api
  module V2
    class IeducarApiBaseController < Api::V2::BaseController
      skip_before_action :api_authenticate_with_header!
      before_action :authenticate_user_from_token!
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response

      private

      def authenticate_user_from_token!
        api_security_token = IeducarApiConfiguration.current.api_security_token

        return if Devise.secure_compare(api_security_token, request.headers['token'])

        render_invalid_token
      end

      def render_invalid_token
        render json: { errors: 'Token inválido' },
               status: :unauthorized
      end

      def render_not_found_response
        render json: { message: 'Elemento não encontrado' },
               status: :not_found
      end
    end
  end
end
