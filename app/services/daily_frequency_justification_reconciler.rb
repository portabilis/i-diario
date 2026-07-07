# frozen_string_literal: true

# Reconcilia o vínculo de justificativa de falta (absence_justification_student_id)
# dos alunos de uma frequência diária com a justificativa daquela aula.
#
# Após o ajuste de falta recriar/converter uma frequência, a aula (class_number) pode
# mudar (ex.: aula 3 -> geral -> aula 1). A justificativa continua amarrada à aula(3)
# original, então a FJ copiada fica desalinhada: o relatório (que lê o vínculo)
# exibe FJ, mas o diário (que casa por aula) não. Este serviço realinha o vínculo com
# o que o diário calcularia para a aula atual — vinculando quando casar e removendo
# quando não casar — garantindo que diário e relatório fiquem sempre consistentes.
class DailyFrequencyJustificationReconciler
  def self.call(daily_frequency, justifications_cache = {})
    new(daily_frequency, justifications_cache).call
  end

  def initialize(daily_frequency, justifications_cache = {})
    @daily_frequency = daily_frequency
    @justifications_cache = justifications_cache
  end

  def call
    students = @daily_frequency.students.reload.to_a
    return if students.empty?

    justified = justified_absences(students.map(&:student_id))

    students.each { |student| reconcile(student, justification_id_for(justified, student.student_id)) }
  end

  private

  def justification_id_for(justified, student_id)
    by_class_number = (justified[student_id] || {})[@daily_frequency.frequency_date] || {}

    # Justificativa geral (0) tem prioridade sobre a da aula específica, igual ao diário.
    by_class_number[0] || by_class_number[@daily_frequency.class_number || 0]
  end

  def justified_absences(student_ids)
    cache_key = [@daily_frequency.classroom_id, @daily_frequency.frequency_date, @daily_frequency.period]

    @justifications_cache[cache_key] ||= AbsenceJustifiedOnDate.call(
      students: student_ids,
      date: @daily_frequency.frequency_date,
      end_date: @daily_frequency.frequency_date,
      classroom: @daily_frequency.classroom_id,
      period: @daily_frequency.period
    )
  end

  def reconcile(student, justification_id)
    return if student.absence_justification_student_id == justification_id

    student.absence_justification_student_id = justification_id
    # Vincular justificativa => present = false (falta). Remover o vínculo NÃO torna o aluno
    # presente: a falta lançada pelo professor permanece.
    student.present = false if justification_id.present?
    student.save!
  rescue ActiveRecord::ActiveRecordError
    Honeybadger.context(daily_frequency_id: @daily_frequency.id, student_id: student.student_id)
    raise
  end
end
