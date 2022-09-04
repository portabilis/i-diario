module Api
  module V2
    class TeacherDisciplinesController < Api::V2::BaseController
      respond_to :json

      def index
        teacher_id = params[:teacher_id]
        classroom_id = params[:classroom_id]

        return unless classroom_id && teacher_id

        @disciplines = Discipline
                         .not_descriptor
                         .by_teacher_and_classroom(teacher_id, classroom_id)
                         .ordered
                         .uniq
      end
    end
  end
end
