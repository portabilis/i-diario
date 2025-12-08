class AbsenceJustificationPreserver
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @frequency_date = params.fetch(:frequency_date).to_date
    @classroom_id = params.fetch(:classroom_id)
    @period = params.fetch(:period)
    @class_number = params.fetch(:class_number).to_i
    @student_ids = Array(params.fetch(:student_ids)).map(&:to_i)
  end

  def call
    return {} if @student_ids.empty?

    absence_justifications = fetch_absence_justifications
    justifications_by_student(absence_justifications)
  end

  private

  def fetch_absence_justifications
    AbsenceJustifiedOnDate.call(
      students: @student_ids,
      date: @frequency_date,
      end_date: @frequency_date,
      classroom: @classroom_id,
      period: @period
    )
  end

  def justifications_by_student(absence_justifications)
    absence_justification_student_id = {}

    @student_ids.each do |student_id|
      absence_justification = absence_justifications[student_id] || {}
      absence_justification = absence_justification[@frequency_date] || {}

      # Busca justificativa APENAS para o class_number específico ou geral (0)
      justification_id = absence_justification[@class_number] || absence_justification[0]

      absence_justification_student_id[student_id] = justification_id if justification_id.present?
    end

    absence_justification_student_id
  end
end
