module Api
  module V2
    # Fronteira de entrada das consultas por unidade e período da API v2:
    # `unity_api_code`, `start_at` e `end_at`.
    #
    # Existe porque entrada MALFORMADA não pode virar resposta plausível: uma
    # data inválida que vira `BETWEEN NULL AND NULL` responde `200 []`, e o
    # consumidor lê "não há dados" onde houve erro de chamada. Aqui o erro é
    # nomeado, com 422.
    #
    # `unity_api_code` aceita uma ou VÁRIAS unidades (`unity_api_code[]=`).
    #
    # Unidade desconhecida NÃO é erro: a chamada está bem formada, e a resposta
    # é a coleção vazia daquela unidade. Quem consome varre a rede pela lista de
    # escolas do i-Educar, onde uma escola nova aparece antes de a sincronização
    # criá-la aqui — devolver erro derrubaria o painel inteiro por causa de uma
    # escola que ainda vai chegar.
    #
    # As datas são ISO 8601 estritas (AAAA-MM-DD), uma cada. `String#to_date`
    # aceitaria "01/02/2026" lendo como 1º de fevereiro, sem sinal de
    # reinterpretação.
    module UnityPeriodParams
      extend ActiveSupport::Concern

      REQUIRED_PARAMS = %i[unity_api_code start_at end_at].freeze
      SINGLE_VALUE_PARAMS = %i[start_at end_at].freeze

      included do
        before_action :validate_unity_period_params!, only: :index
      end

      private

      def validate_unity_period_params!
        message = missing_params_message || single_value_params_message || period_message

        render json: { error: message }, status: :unprocessable_entity if message
      end

      def missing_params_message
        missing = REQUIRED_PARAMS.select { |name| params[name].blank? }

        "Os seguintes parâmetros são obrigatórios: #{missing.join(', ')}" if missing.any?
      end

      # O período é um só; a lista de unidades é que pode ter vários valores.
      def single_value_params_message
        repeated = SINGLE_VALUE_PARAMS.reject { |name| params[name].is_a?(String) }
        repeated << :unity_api_code unless unity_api_codes.all? { |code| code.is_a?(String) }

        "Os seguintes parâmetros aceitam um único valor: #{repeated.join(', ')}" if repeated.any?
      end

      def period_message
        return 'Os parâmetros start_at e end_at devem estar no formato AAAA-MM-DD' if start_at.nil? || end_at.nil?

        'O parâmetro start_at deve ser anterior ou igual a end_at' if start_at > end_at
      end

      def unity_api_codes
        @unity_api_codes ||= Array.wrap(params[:unity_api_code]).uniq
      end

      def unities
        @unities ||= Unity.where(api_code: unity_api_codes).to_a
      end

      def start_at
        @start_at ||= parse_iso_date(params[:start_at])
      end

      def end_at
        @end_at ||= parse_iso_date(params[:end_at])
      end

      def parse_iso_date(value)
        Date.iso8601(value)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
