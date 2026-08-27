module Api
  module V2
    class FrequencyRecordCompletenessController < Api::V2::BaseController
      include Api::V2::UnityPeriodParams

      before_action :authenticate_api!
      respond_to :json

      def index
        render json: Api::FrequencyRecordCompletenessService.call(unities: unities, start_at: start_at, end_at: end_at),
               root: false
      end
    end
  end
end
