# Ponto único de disparo do envio automático de faltas ao i-Educar após o registro de frequência
# (diário, frequência em lote e aplicativo). O escopo do envio é a turma, o professor informado pelo
# canal e a etapa de cada data: datas que caem na mesma etapa produzem um único job.
class AutomaticAbsencePostingEnqueuer
  def self.call(entity_id:, classroom_id:, frequency_dates:, teacher_id:, force_posting: false)
    new(
      entity_id: entity_id,
      classroom_id: classroom_id,
      frequency_dates: frequency_dates,
      teacher_id: teacher_id,
      force_posting: force_posting
    ).call
  end

  def initialize(entity_id:, classroom_id:, frequency_dates:, teacher_id:, force_posting: false)
    @entity_id = entity_id
    @classroom_id = classroom_id
    @frequency_dates = Array(frequency_dates)
    @teacher_id = teacher_id
    @force_posting = force_posting
  end

  def call
    return unless GeneralConfiguration.current.automatic_absence_posting
    return if scope_incomplete?

    postable_steps.each { |step| enqueue(step.to_number) }
  end

  private

  attr_reader :entity_id, :classroom_id, :frequency_dates, :teacher_id, :force_posting

  # owner_teacher_id é nulo em parte dos diários e a turma pode ter sido removida pela
  # sincronização. Sem um dos dois não há envio possível, e o silêncio aqui chega ao suporte como
  # "as faltas não subiram" sem nada nos logs que distinga isso de a configuração estar desligada.
  def scope_incomplete?
    return false if teacher_id.present? && classroom.present?

    Rails.logger.warn(
      key: 'AutomaticAbsencePostingEnqueuer#call',
      message: 'envio automático de faltas ignorado por falta de turma ou professor',
      entity_id: entity_id,
      classroom_id: classroom_id,
      teacher_id: teacher_id
    )

    true
  end

  # Uma única resolução de turma e de calendário para todas as datas: no lançamento em lote a
  # alternativa é repetir esse trabalho por dia letivo do intervalo.
  def steps
    @steps ||= begin
      steps_fetcher = StepsFetcher.new(classroom)
      steps_by_date = frequency_dates.uniq.map { |date| [date, steps_fetcher.step_by_date(date)] }

      log_dates_without_step(steps_by_date)

      steps_by_date.map(&:last).compact.uniq
    end
  end

  # Mesmas duas regras da tela de envio (IeducarApiExamPostingsController#require_current_posting_step
  # e #steps): a etapa só é enviada com a janela de lançamento aberta hoje, e a permissão de envio
  # sem restrição de data é o que libera fora dela.
  def postable_steps
    return steps if posting_without_restrictions?

    open_steps, closed_steps = steps.partition { |step| posting_window_open?(step) }

    log_closed_steps(closed_steps)

    open_steps
  end

  def posting_without_restrictions?
    User.current.try(:can_change?, Features::IEDUCAR_API_EXAM_POSTING_WITHOUT_RESTRICTIONS).present?
  end

  def posting_window_open?(step)
    return false if step.start_date_for_posting.blank? || step.end_date_for_posting.blank?

    (step.start_date_for_posting.to_date..step.end_date_for_posting.to_date).cover?(Time.zone.today)
  end

  def log_closed_steps(steps)
    return if steps.empty?

    Rails.logger.info(
      key: 'AutomaticAbsencePostingEnqueuer#call',
      message: 'etapas fora da janela de lançamento ignoradas no envio automático de faltas',
      entity_id: entity_id,
      classroom_id: classroom_id,
      step_numbers: steps.map(&:to_number)
    )
  end

  # Data fora de qualquer etapa não tem envio possível: o total de faltas é sempre por etapa.
  def log_dates_without_step(steps_by_date)
    dates = steps_by_date.select { |_date, step| step.blank? }.map(&:first)
    return if dates.empty?

    Rails.logger.warn(
      key: 'AutomaticAbsencePostingEnqueuer#call',
      message: 'datas fora de qualquer etapa ignoradas no envio automático de faltas',
      entity_id: entity_id,
      classroom_id: classroom_id,
      frequency_dates: dates.map(&:to_s)
    )
  end

  def enqueue(step_number)
    AutomaticAbsencePostingWorker.perform_async(entity_id, classroom.id, teacher_id, step_number, force_posting)
  rescue Redis::BaseConnectionError => e
    # A frequência já está gravada: indisponibilidade do Redis não pode derrubar a resposta nem
    # desfazer a escrita. O envio fica para a próxima gravação da turma.
    notify_enqueue_failure(e, step_number)
  end

  def notify_enqueue_failure(error, step_number)
    context = {
      entity_id: entity_id,
      classroom_id: classroom_id,
      teacher_id: teacher_id,
      step_number: step_number
    }

    Rails.logger.error(context.merge(key: 'AutomaticAbsencePostingEnqueuer#enqueue', message: error.message))
    Honeybadger.notify(error, context: context)
  end

  def classroom
    return @classroom if defined?(@classroom)

    @classroom = Classroom.find_by(id: classroom_id)
  end
end
