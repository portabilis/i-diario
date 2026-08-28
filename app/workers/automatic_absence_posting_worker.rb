# Cria um envio de faltas ao i-Educar restrito a uma turma, em nome do professor informado pelo
# canal que registrou a frequência, para a etapa informada. A partir daí o fluxo é o mesmo do envio
# manual (IeducarExamPostingWorker → ExamPoster::AbsencePoster → Ieducar::SendPostWorker).
#
# O lock until_executing faz gravações repetidas, enquanto o job ainda espera na fila, colapsarem
# num único envio: o poster lê o estado atual da frequência quando roda.
class AutomaticAbsencePostingWorker
  include Sidekiq::Worker

  # Fila do fluxo automático inteiro — montagem das requisições e envio. O envio manual monta na
  # exam_posting e só envia na critical. A critical tem processo próprio com concorrência 1; o
  # processo padrão tem mais threads que o pool de conexões e o esgota com um job por aluno.
  QUEUE = 'critical'.freeze

  sidekiq_options queue: QUEUE,
                  retry: 2,
                  dead: false,
                  unique: :until_executing,
                  unique_args: ->(args) { args },
                  on_conflict: :log

  # Sem dead set, uma falha aqui não deixa nem o registro de envio para trás: o Honeybadger é o
  # único rastro de que a frequência gravada não chegou ao i-Educar.
  sidekiq_retries_exhausted do |message, exception|
    entity_id, classroom_id, teacher_id, step_number, _force_posting = message['args']

    Honeybadger.notify(
      exception,
      context: {
        entity_id: entity_id,
        classroom_id: classroom_id,
        teacher_id: teacher_id,
        step_number: step_number
      }
    )
  end

  def perform(entity_id, classroom_id, teacher_id, step_number, force_posting)
    @entity_id = entity_id
    @classroom_id = classroom_id
    @teacher_id = teacher_id
    @step_number = step_number
    @force_posting = force_posting

    Entity.find(entity_id).using_connection do
      # Reconferido aqui de propósito: entre o enfileiramento e a execução a configuração pode ter
      # sido desligada, e é isto que cancela na prática os jobs já na fila.
      return unless enabled?
      return if scope_incomplete?

      launch
    end
  end

  private

  attr_reader :entity_id, :classroom_id, :teacher_id, :step_number, :force_posting

  def enabled?
    GeneralConfiguration.current.automatic_absence_posting && ieducar_api_configuration.persisted?
  end

  def scope_incomplete?
    return false if classroom.present? && teacher.present? && step.present?

    Rails.logger.warn(
      key: 'AutomaticAbsencePostingWorker#perform',
      message: 'envio automático de faltas ignorado por turma, professor ou etapa inexistente',
      entity_id: entity_id,
      classroom_id: classroom_id,
      teacher_id: teacher_id,
      step_number: step_number
    )

    true
  end

  def classroom
    return @classroom if defined?(@classroom)

    @classroom = Classroom.find_by(id: classroom_id)
  end

  def teacher
    return @teacher if defined?(@teacher)

    @teacher = Teacher.find_by(id: teacher_id)
  end

  def step
    return @step if defined?(@step)

    @step = classroom && StepsFetcher.new(classroom).step(step_number)
  end

  def launch
    IeducarExamPostingLauncher.call(
      attributes: posting_attributes,
      entity_id: entity_id,
      force_posting: force_posting,
      queue: QUEUE
    )
  end

  def ieducar_api_configuration
    @ieducar_api_configuration ||= IeducarApiConfiguration.current
  end

  def posting_attributes
    {
      post_type: ApiPostingTypes::ABSENCE,
      automatic: true,
      ieducar_api_configuration: ieducar_api_configuration,
      classroom: classroom,
      teacher: teacher,
      step_attribute => step
    }
  end

  def step_attribute
    step.is_a?(SchoolCalendarClassroomStep) ? :school_calendar_classroom_step : :school_calendar_step
  end
end
