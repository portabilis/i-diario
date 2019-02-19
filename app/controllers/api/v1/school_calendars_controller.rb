module Api
  module V1
    class SchoolCalendarsController < Api::V1::BaseController
      respond_to :json

      def index
        unity = Unity.find(id: params[:unity_id])

        return unless unity

        render json: CurrentSchoolCalendarFetcher.new(unity, nil).fetch
      end
    end
  end
end
