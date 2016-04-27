class AbsenceJustification < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit
  include Filterable

  belongs_to :student
  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar
  belongs_to :teacher

  validates :teacher,          presence: true
  validates :student_id,       presence: true
  validates :unity,            presence: true
  validates :classroom_id,     presence: true
  validates :school_calendar,  presence: true
  validates :absence_date_end, presence: true
  validates :absence_date,     presence: true
  validates :discipline_id,    presence: true,
                               if: :frequence_type_by_discipline?
  validates :justification,    presence: true

  validate :period_absence
  validate :absence_date_cannot_be_greater_than_absence_date_end
  validate :absence_date_end_must_be_lower_than_today
  validate :is_school_day?

  scope :ordered, -> { order(absence_date: :desc) }

  # search scopes
  scope :by_teacher, lambda { |teacher_id| where(teacher_id: teacher_id)  }
  scope :by_classroom, lambda { |classroom_id| where("classroom_id = ? OR classroom_id IS NULL", classroom_id) }
  scope :by_student, lambda { |student| joins(:student).where('students.name ILIKE ?', "%#{student}%") }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_student_id, lambda { |student_id| where(student_id: student_id) }
  scope :by_date_range, lambda { |absence_date, absence_date_end| where("absence_date <= ? AND absence_date_end >= ?", absence_date_end, absence_date) }
  scope :by_unity, lambda { |unity| where("unity_id = ? OR unity_id IS NULL", unity) }
  scope :by_school_calendar, lambda { |school_calendar| where("school_calendar_id = ? OR school_calendar_id IS NULL", school_calendar) }
  scope :by_date, lambda { |date| by_date_query(date) }
  scope :by_date_report, lambda { |absence_date, absence_date_end| where("absence_date >= ? AND absence_date_end <= ?", absence_date, absence_date_end) }
  scope :by_school_calendar_report, lambda { |school_calendar| where(school_calendar: school_calendar)  }

  private

  def is_school_day?
    return unless school_calendar && absence_date && absence_date_end && classroom

    errors.add(:absence_date, "O dia #{absence_date.strftime("%d/%m/%Y")} não é um dia letivo") if !school_calendar.school_day?(absence_date, classroom.grade.id, classroom.id)
    errors.add(:absence_date_end, "O dia #{absence_date_end.strftime("%d/%m/%Y")} não é um dia letivo") if !school_calendar.school_day?(absence_date_end, classroom.grade.id, classroom.id)
  end

  def self.by_date_query(date)
    date = date.to_date
    where(
      AbsenceJustification.arel_table[:absence_date]
      .lteq(date)
      .and(AbsenceJustification.arel_table[:absence_date_end].gteq(date))
    )
  end

  def absence_date_end_must_be_lower_than_today
    if absence_date_end.present?
      errors.add(:absence_date_end, "Deve ser menor ou igual a data de hoje") if absence_date_end > Time.zone.today
    end
  end

  def absence_date_cannot_be_greater_than_absence_date_end
    if (absence_date.present? && absence_date_end.present?)
      errors.add(:absence_date, "Data inicial não pode ser maior que a final") if absence_date > absence_date_end
    end
  end

  def period_absence
    absence_justifications = AbsenceJustification.by_classroom(classroom)
      .by_student_id(student_id)
      .by_discipline_id(discipline_id)
      .by_date_range(absence_date, absence_date_end)

    absence_justifications = absence_justifications.where.not(id: id) if persisted?

    if absence_justifications.any?
      errors.add(:base, :discipline_period_absence) if frequence_type_by_discipline?
      errors.add(:absence_date, "Já existe justificativa para essa data")
      errors.add(:absence_date_end, "Já existe justificativa para essa data")
    end
  end

  def frequence_type_by_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end
end
