module Api
  module V2
    # Os dias letivos de cada unidade, como conjunto de datas.
    #
    # Existe porque contar dias letivos e SABER QUAIS SÃO são coisas
    # diferentes: prazo em dias letivos, sequência de presenças e denominador
    # de completude só se calculam com o calendário na mão, e o que já se
    # expunha era fronteira de bimestre ou uma contagem.
    class UnitySchoolDaysController < Api::V2::BaseController
      before_action :authenticate_api!
      respond_to :json

      def index
        return if missing_required_params?

        render json: school_days_by_unity, root: false
      end

      private

      def school_days_by_unity
        UnitySchoolDay.joins(:unity)
                      .where(unities: { api_code: params[:unity_api_code] })
                      .by_date_between(params[:start_at], params[:end_at])
                      .order(:school_day)
                      .pluck('unities.api_code', :school_day)
                      .group_by(&:first)
                      .map do |unity_api_code, days|
                        {
                          unity_api_code: unity_api_code,
                          school_days: days.map { |day| day.last.to_s }
                        }
                      end
      end

      def missing_required_params?
        required_params = %i[unity_api_code start_at end_at]
        missing = required_params.select { |param| params[param].blank? }

        return false if missing.empty?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing.join(', ')}" },
               status: :unprocessable_entity
        true
      end
    end
  end
end
