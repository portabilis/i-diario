class OldStepsConceptualValuesController < ApplicationController
  respond_to :json

  before_action :authorize_conceptual_values_reading

  def index
    classroom = Classroom.find(params[:classroom_id])
    student = Student.find(params[:student_id])
    step = StepsFetcher.new(classroom).step_by_id(params[:step_id])

    log_unreachable_step(classroom, student) if step.blank?

    render(json: OldStepsConceptualValuesFetcher.new(classroom, student, step).fetch)
  end

  private

  # A feature `conceptual_exams` autoriza a tela, não uma turma: o recorte por turma é o
  # vínculo em teacher_discipline_classrooms, que é a fonte de autorização de lançamento do
  # professor. Administrador e servidor operam a rede inteira e não passam por ele.
  def authorize_conceptual_values_reading
    authorize(ConceptualExam)

    return if current_user.current_role_is_admin_or_employee?
    return if Classroom.by_teacher_id(current_teacher_id).exists?(id: params[:classroom_id])

    raise Pundit::NotAuthorizedError
  end

  def log_unreachable_step(classroom, student)
    Rails.logger.warn(
      '[OldStepsConceptualValues] etapa fora do calendário da turma - ' \
      "entity: #{Entity.current&.name}, classroom_id: #{classroom.id}, " \
      "student_id: #{student.id}, step_id: #{params[:step_id]}"
    )
  end
end
