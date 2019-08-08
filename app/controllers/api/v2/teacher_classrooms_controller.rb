# frozen_string_literal: true

module Api
  module V2
    class TeacherClassroomsController < Api::V2::BaseController
      respond_to :json

      def index
        teacher_id = params[:teacher_id]
        unity_id = params[:unity_id]

        return unless teacher_id && unity_id

        @classrooms = Classroom.by_unity_and_teacher(
          unity_id,
          teacher_id
        ).ordered.uniq

        @classrooms
      end

      # rubocop:disable Naming/PredicateName
      def has_activities
        teacher_id = Teacher.find_by!(api_code: params[:teacher_id])
        classroom_id = Classroom.find_by!(api_code: params[:classroom_id])
        checker = TeacherClassroomActivity.new(teacher_id, classroom_id)

        render json: checker.any_activity?
      end
      # rubocop:enable Naming/PredicateName
    end
  end
end
