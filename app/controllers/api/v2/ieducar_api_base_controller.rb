module Api
  module V2
    class IeducarApiBaseController < Api::V2::BaseController
      skip_before_action :api_authenticate_with_header!
      before_action :authenticate_user_from_token!

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
    end
  end
end
