module Api
  module V2
    class SchoolCalendarsController < Api::V2::BaseController
      respond_to :json

      def index
        unity = Unity.find_by(id: params[:unity_id])

        return unless unity

        @school_calendar = CurrentSchoolCalendarFetcher.new(unity, nil).fetch
      end
    end
  end
end
