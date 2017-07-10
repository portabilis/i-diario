class Api::V1::LessonPlansController < Api::V1::BaseController
  respond_to :json

  def index
    return unless params[:teacher_id]
    @lesson_plans = LessonPlan.by_teacher_id(params[:teacher_id])
                              .current
                              .includes(classroom: :unity)
  end
end
