# Ponto único de disparo do envio automático de faltas ao i-Educar após o registro de frequência
# (diário, frequência em lote e aplicativo). O escopo do envio é a turma, o professor que
# registrou e a etapa da data — gravações em dias diferentes da mesma etapa caem no mesmo job.
class AutomaticAbsencePostingEnqueuer
  def self.call(entity_id:, classroom_id:, frequency_date:, teacher_id:, force_posting: false)
    new(
      entity_id: entity_id,
      classroom_id: classroom_id,
      frequency_date: frequency_date,
      teacher_id: teacher_id,
      force_posting: force_posting
    ).call
  end

  def initialize(entity_id:, classroom_id:, frequency_date:, teacher_id:, force_posting: false)
    @entity_id = entity_id
    @classroom_id = classroom_id
    @frequency_date = frequency_date
    @teacher_id = teacher_id
    @force_posting = force_posting
  end

  def call
    return unless GeneralConfiguration.current.automatic_absence_posting
    return if teacher_id.blank? || classroom.blank? || step_number.blank?

    AutomaticAbsencePostingWorker.perform_async(entity_id, classroom.id, teacher_id, step_number, force_posting)
  end

  private

  attr_reader :entity_id, :classroom_id, :frequency_date, :teacher_id, :force_posting

  def classroom
    @classroom ||= Classroom.find_by(id: classroom_id)
  end

  def step_number
    @step_number ||= StepsFetcher.new(classroom).step_by_date(frequency_date).try(:to_number)
  end
end
