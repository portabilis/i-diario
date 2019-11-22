module Api
  module V2
    class TeacherUnitiesController < Api::V2::BaseController
      respond_to :json

      def index
        return unless params[:teacher_id]

        @unities = Unity.by_teacher(params[:teacher_id])
                        .by_year(Date.current.year)
                        .by_posting_date(Date.current)
                        .ordered
                        .uniq

        @unities
      end
    end
  end
end
