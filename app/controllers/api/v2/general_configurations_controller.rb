module Api
  module V2
    # A régua de infrequência que o município configurou. Existe para quem
    # consome poder exibir e testar a régua real da rede em vez de repetir um
    # padrão sugerido — o limiar é decisão do município, nunca de quem lê.
    class GeneralConfigurationsController < Api::V2::BaseController
      before_action :authenticate_api!
      respond_to :json

      def show
        configuration = GeneralConfiguration.current

        render json: {
          notify_consecutive_or_alternate_absences: configuration.notify_consecutive_or_alternate_absences,
          max_consecutive_absence_days: configuration.max_consecutive_absence_days,
          max_alternate_absence_days: configuration.max_alternate_absence_days,
          days_to_consider_alternate_absences: configuration.days_to_consider_alternate_absences
        }, root: false
      end
    end
  end
end
