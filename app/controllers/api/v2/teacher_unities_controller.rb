module Api
  module V2
    class TeacherUnitiesController < Api::V2::BaseController
      respond_to :json

      def index
        return unless params[:teacher_id]

        unities_with_calendar = Unity.by_teacher(params[:teacher_id])
                        .by_posting_date(Date.current)
                        .by_teacher_with_school_calendar_year
                        .ordered

        unities_with_calendar_in_classroom = Unity.by_teacher(params[:teacher_id])
                        .by_posting_date_in_classroom(Date.current)
                        .by_teacher_with_school_calendar_year
                        .ordered

        @unities = (unities_with_calendar + unities_with_calendar_in_classroom).sort.uniq
      end
    end
  end
end
