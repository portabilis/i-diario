class OldStepsConceptualValuesController < ApplicationController
  respond_to :json

  def index
    classroom = Classroom.find(params[:classroom_id])
    student = Student.find(params[:student_id])
    step = StepsFetcher.new(classroom).step_by_id(params[:step_id])

    log_unreachable_step(classroom, student) if step.blank?

    render(json: OldStepsConceptualValuesFetcher.new(classroom, student, step).fetch)
  end

  private

  def log_unreachable_step(classroom, student)
    Rails.logger.warn(
      '[OldStepsConceptualValues] etapa fora do calendário da turma - ' \
      "entity: #{Entity.current&.name}, classroom_id: #{classroom.id}, " \
      "student_id: #{student.id}, step_id: #{params[:step_id]}"
    )
  end
end
