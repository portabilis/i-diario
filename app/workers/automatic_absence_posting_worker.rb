# Cria um envio de faltas ao i-Educar restrito a uma turma, em nome do professor que registrou a
# frequência, para a etapa informada. A partir daí o fluxo é o mesmo do envio manual
# (IeducarExamPostingWorker → ExamPoster::AbsencePoster → Ieducar::SendPostWorker).
#
# O lock until_executing faz gravações repetidas, enquanto o job ainda espera na fila, colapsarem
# num único envio: o poster lê o estado atual da frequência quando roda.
class AutomaticAbsencePostingWorker
  include Sidekiq::Worker

  # Mesma fila do envio manual, usada pelo fluxo automático inteiro — montagem das requisições e
  # envio. Ela tem processo próprio com concorrência 1; o processo padrão tem mais threads que o
  # pool de conexões e esgota o pool com um job por aluno.
  QUEUE = 'critical'.freeze

  sidekiq_options queue: QUEUE,
                  retry: 2,
                  dead: false,
                  unique: :until_executing,
                  unique_args: ->(args) { args },
                  on_conflict: :log

  def perform(entity_id, classroom_id, teacher_id, step_number, force_posting)
    Entity.find(entity_id).using_connection do
      return unless enabled?

      classroom = Classroom.find_by(id: classroom_id)
      teacher = Teacher.find_by(id: teacher_id)
      step = classroom && StepsFetcher.new(classroom).step(step_number)
      return if classroom.blank? || teacher.blank? || step.blank?

      launch(entity_id, force_posting, posting_attributes(classroom, teacher, step))
    end
  end

  private

  def launch(entity_id, force_posting, attributes)
    IeducarExamPostingLauncher.call(
      attributes: attributes,
      entity_id: entity_id,
      force_posting: force_posting,
      queue: QUEUE
    )
  end

  def enabled?
    GeneralConfiguration.current.automatic_absence_posting && ieducar_api_configuration.persisted?
  end

  def ieducar_api_configuration
    @ieducar_api_configuration ||= IeducarApiConfiguration.current
  end

  def posting_attributes(classroom, teacher, step)
    {
      post_type: ApiPostingTypes::ABSENCE,
      automatic: true,
      ieducar_api_configuration: ieducar_api_configuration,
      classroom: classroom,
      teacher: teacher,
      step_attribute(step) => step
    }
  end

  def step_attribute(step)
    step.is_a?(SchoolCalendarClassroomStep) ? :school_calendar_classroom_step : :school_calendar_step
  end
end
