module Api
  module V2
    class SchoolCalendarsController < Api::V2::BaseController
      respond_to :json

      def index
        unity = Unity.find_by(id: params[:unity_id])

        return unless unity

        @school_calendar = SchoolCalendar.only_opened_years
                                         .by_unity_id(params[:unity_id])
                                         .order(:year)
                                         .first
      end
    end
  end
end
