module Api
  module V2
    class DisciplineActivityController < Api::V2::BaseController
      respond_to :json

      def check
        discipline = Discipline.find_by!(api_code: params[:discipline])

        classrooms_api_codes = params[:classrooms].split(',')
        classrooms_ids = Classroom.where(api_code: classrooms_api_codes).pluck(:id)

        render json: activity?(discipline.id, classrooms_ids)
      end

      private

      def activity?(discipline_id, classrooms_ids)
        activity_checker = DisciplineClassroomActivity.new(discipline_id, classrooms_ids)
        activity_checker.any_activity?
      end
    end
  end
end
