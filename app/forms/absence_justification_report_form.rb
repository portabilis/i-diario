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
  validates :absence_date,     presence: true
  validates :absence_date_end, presence: true
  validates :discipline_id,     presence: true,
                               if: :frequence_type_by_discipline?

  validate :absence_date_must_be_a_valid_date
  validate :absence_date_end_must_be_a_valid_date
  validate :absence_date_cannot_be_greater_than_absence_date_end
  validate :must_find_absence
  validate :absence_date_end_must_be_lower_than_today

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

  def absence_date_must_be_a_valid_date
    return if errors[:absence_date].any?

    begin
      absence_date.to_date
    rescue ArgumentError
      errors.add(:absence_date, "Deve ser uma data válida")
    end
  end

  def absence_date_end_must_be_a_valid_date
    return if errors[:absence_date_end].any?

    begin
      absence_date_end.to_date
    rescue ArgumentError
      errors.add(:absence_date_end, "Deve ser uma data válida")
    end
  end

  def must_find_absence
    return unless errors.blank?

    if absence_justification.blank?
      errors.add(:base, "Não foram encontrados resultados para a pesquisa!")
    end
  end

  def absence_date_end_must_be_lower_than_today
    return if errors[:absence_date_end].any?

    begin
      absence_date.to_date
      if absence_date_end.present?
        errors.add(:absence_date_end, "Deve ser menor ou igual a data de hoje") if absence_date_end.to_date > Time.zone.today
      end
    rescue ArgumentError
      errors.add(:absence_date_end, "Deve ser uma data válida")
    end
  end

  def absence_date_cannot_be_greater_than_absence_date_end
    if (absence_date.present? && absence_date_end.present?)
      errors.add(:absence_date, "Data inicial não pode ser maior que a final") if absence_date > absence_date_end
    end
  end

  def classroom
    Classroom.find(classroom_id) if classroom_id.present?
  end
end
