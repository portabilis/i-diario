module Api
  module V2
    class TeacherUnitiesController < Api::V2::BaseController
      respond_to :json

      def index
        return unless params[:teacher_id]

        @unities = Unity.by_teacher(params[:teacher_id])
                        .by_posting_date(Date.current)
                        .by_teacher_with_school_calendar_year
                        .ordered
                        .uniq

        @unities
      end
    end
  end
end
