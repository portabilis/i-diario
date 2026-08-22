module Api
  module V2
    class InfrequencyTrackingsController < Api::V2::BaseController
      before_action :authenticate_api!
      respond_to :json

      def index
        return if missing_required_params?

        render json: Api::InfrequencyTrackingsService.call(
          unity_api_code: params[:unity_api_code],
          start_at: params[:start_at],
          end_at: params[:end_at]
        ), root: false
      end

      private

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
