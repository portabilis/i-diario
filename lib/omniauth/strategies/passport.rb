require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Passport < OmniAuth::Strategies::OAuth2
      option :name, 'passport'

      option :client_options,
        site: Rails.application.secrets.PASSPORT_URL,
        authorize_url: Rails.application.secrets.PASSPORT_AUTHORIZE_URL,
        token_url: Rails.application.secrets.PASSPORT_TOKEN_URL,
        ssl: { verify: !Rails.env.development? }

      uid { raw_info['sub'] || raw_info['id'].to_s }

      info do
        { email: raw_info['email'] }
      end

      def raw_info
        @raw_info ||= access_token.get(Rails.application.secrets.PASSPORT_USER_URL).parsed
      end

      def callback_url
        full_host + callback_path
      end
    end
  end
end
