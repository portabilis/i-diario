# Reconcilia a justificativa de falta (absence_justification_student_id)
# dos alunos de uma frequência diária com a justificativa daquela aula.
#
# Após o ajuste de falta recriar/converter uma frequência, a aula (class_number) pode
# mudar (ex.: aula 3 -> geral -> aula 1). A justificativa continua amarrada à aula(3)
# original, então a FJ copiada fica desalinhada: o relatório (que lê a etiqueta)
# exibe FJ, mas o diário (que casa por aula) não. Este serviço realinha a etiqueta com
# o que o diário calcularia para a aula atual — vinculando quando casar e removendo
# quando não casar — garantindo que diário e relatório fiquem sempre consistentes.
class DailyFrequencyJustificationReconciler
  def self.call(daily_frequency)
    new(daily_frequency).call
  end

  def initialize(daily_frequency)
    @daily_frequency = daily_frequency
  end

  def call
    students = @daily_frequency.students.reload.to_a
    return if students.empty?

    justifications_by_student = fetch_justifications(students)

    students.each { |student| reconcile(student, justifications_by_student[student.student_id]) }
  end

  private

  def fetch_justifications(students)
    AbsenceJustificationPreserver.call(
      frequency_date: @daily_frequency.frequency_date,
      classroom_id: @daily_frequency.classroom_id,
      period: @daily_frequency.period,
      class_number: @daily_frequency.class_number || 0,
      student_ids: students.map(&:student_id)
    )
  end

  def reconcile(student, justification_id)
    return if student.absence_justification_student_id == justification_id

    student.absence_justification_student_id = justification_id
    student.present = false if justification_id.present?
    student.save!
  end
end
