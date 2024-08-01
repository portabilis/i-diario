module Api
  module V2
    class ListAttendancesByClassroomController < Api::V2::BaseController
      respond_to :json

      def index
        unity = Unity.find_by(api_code: params[:unity])
        start_at = params[:start_at]
        end_at = params[:end_at]
        year = params[:year]

        raise ArgumentError if unity.blank?

        render json: ClassroomAttendanceService.call(unity, start_at, end_at, year)
      end
    end
  end
end
