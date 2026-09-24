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

  # A feature `conceptual_exams` autoriza a tela, não uma turma. O alcance por turma é o
  # mesmo do seletor de perfil: administrador escolhe qualquer unidade, servidor fica na
  # unidade do papel atual e professor nas turmas do vínculo em teacher_discipline_classrooms,
  # que é a fonte de autorização de lançamento.
  def authorize_conceptual_values_reading
    authorize(ConceptualExam)

    return if current_user.administrator?
    return if reachable_classrooms.exists?(id: params[:classroom_id])

    raise Pundit::NotAuthorizedError
  end

  def reachable_classrooms
    return Classroom.by_unity_id(current_user.current_user_role.unity_id) if current_user.employee?

    Classroom.by_teacher_id(current_teacher_id)
  end

  def log_unreachable_step(classroom, student)
    Rails.logger.warn(
      '[OldStepsConceptualValues] etapa fora do calendário da turma - ' \
      "entity: #{Entity.current&.name}, classroom_id: #{classroom.id}, " \
      "student_id: #{student.id}, step_id: #{params[:step_id]}"
    )
  end
end
