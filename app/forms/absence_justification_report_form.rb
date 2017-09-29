class AbsenceJustificationReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :absence_date,
                :absence_date_end,
                :school_calendar_year,
                :current_teacher_id

  validates :absence_date, presence: true, date: true, timeliness: { before: :absence_date_end, type: :date, before_message: 'não pode ser maior que a Data final' }
  validates :absence_date_end, presence: true, date: true, timeliness: { on_or_after: :absence_date, type: :date, on_or_after_message: 'deve ser maior ou igual a Data inicial' }
  validates :unity_id,         presence: true
  validates :classroom_id,     presence: true
  validates :discipline_id,    presence: true,
                               if: :frequence_type_by_discipline?


  validate :must_find_absence

  def absence_justification
    if frequence_type_by_discipline?
      AbsenceJustification.by_teacher(current_teacher_id)
                          .by_unity(unity_id)
                          .by_school_calendar_report(school_calendar_year)
                          .by_classroom(classroom_id)
                          .by_discipline_id(discipline_id)
                          .by_date_report(absence_date, absence_date_end)
                          .ordered
    else
      AbsenceJustification.by_teacher(current_teacher_id)
                          .by_unity(unity_id)
                          .by_school_calendar_report(school_calendar_year)
                          .by_classroom(classroom_id)
                          .by_date_report(absence_date, absence_date_end)
                          .ordered
    end
  end

  def frequence_type_by_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher_id)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  private

  def must_find_absence
    return unless errors.blank?

    if absence_justification.blank?
      errors.add(:base, "Não foram encontrados resultados para a pesquisa!")
    end
  end

  def classroom
    Classroom.find(classroom_id) if classroom_id.present?
  end
end
