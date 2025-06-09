module Api
  module V2
    class TeacherClassroomsController < Api::V2::BaseController
      respond_to :json

      def index
        teacher_id = params[:teacher_id]
        unity_id = params[:unity_id]

        return unless teacher_id && unity_id

        active_years = SchoolCalendar.where(
          opened_year: true,
          unity_id: unity_id
        ).pluck(:year).uniq

        @classrooms = Classroom.by_unity_and_teacher(
          unity_id,
          teacher_id
        ).where(year: active_years).uniq

        @classrooms
      end

      def has_activities
        teacher = Teacher.find_by(api_code: params[:teacher_id])
        classroom = Classroom.find_by(api_code: params[:classroom_id])

        if teacher.blank? || classroom.blank?
          render json: { error: 'Professor ou turma não encontrados' }, status: :not_found
          return
        end

        checker = TeacherClassroomActivity.new(teacher.id, classroom.id)

        render json: checker.any_activity?
      end
    end
  end
end
