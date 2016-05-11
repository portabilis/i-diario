class AbsenceJustificationReportForm
  include ActiveModel::Model

  attr_accessor :unity,
                :classroom_id,
                :discipline_id,
                :absence_date,
                :absence_date_end,
                :school_calendar_year,
                :current_teacher_id

  validates :unity,            presence: true
  validates :classroom_id,     presence: true
  validates :discipline_id,     presence: true,
                               if: :frequence_type_by_discipline?
  validates(
    :absence_date,
    presence: true,
    date: { less_than_or_equal_to: :absence_date_end, not_in_future: true }
  )
  validates(
    :absence_date_end,
    presence: true,
    date: { greater_than_or_equal_to: :absence_date, not_in_future: true }
  )

  validate :must_find_absence

  def absence_justification
    if discipline_id.present?
      AbsenceJustification.by_teacher(current_teacher_id)
                          .by_unity(unity)
                          .by_school_calendar_report(school_calendar_year)
                          .by_classroom(classroom_id)
                          .by_discipline_id(discipline_id)
                          .by_date_report(absence_date, absence_date_end)
                          .ordered
    else
      AbsenceJustification.by_teacher(current_teacher_id)
                          .by_unity(unity)
                          .by_school_calendar_report(school_calendar_year)
                          .by_classroom(classroom_id)
                          .by_date_report(absence_date, absence_date_end)
                          .ordered
    end
  end

  private

  def frequence_type_by_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher_id)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end



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
