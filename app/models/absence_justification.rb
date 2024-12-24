class AbsenceJustification < ApplicationRecord
  include Audit
  include Filterable
  include Discardable
  include ColumnsLockable
  include TeacherRelationable

  not_updatable only: :classroom_id
  teacher_relation_columns only: [:classroom]

  acts_as_copy_target

  audited

  before_destroy :valid_for_destruction?
  before_destroy :remove_attachments, if: :valid_for_destruction?

  has_many :absence_justifications_students, dependent: :destroy
  has_many :students, through: :absence_justifications_students
  has_many :absence_justifications_disciplines, dependent: :destroy
  has_many :disciplines, through: :absence_justifications_disciplines
  belongs_to :unity
  belongs_to :classroom
  belongs_to :school_calendar
  belongs_to :teacher
  belongs_to :user

  has_many :absence_justification_attachments, dependent: :destroy

  accepts_nested_attributes_for :absence_justification_attachments, allow_destroy: true

  validates_date :absence_date, :absence_date_end
  validates :teacher, presence: true
  validates :user, presence: true
  validates :unity, presence: true
  validates :classroom_id, presence: true
  validates :school_calendar, presence: true
  validates :absence_date_end, presence: true, school_calendar_day: true, posting_date: true
  validates :absence_date, presence: true, school_calendar_day: true, posting_date: true

  validate :at_least_one_student
  validate :period_absence
  validate :no_retroactive_dates

  has_enumeration_for :period, with: Periods, skip_validation: true

  default_scope -> { kept }

  scope :ordered, -> { order(absence_date: :desc) }
  scope :by_teacher, ->(teacher_id) { where(teacher_id: teacher_id)  }
  scope :by_classroom, ->(classroom_id) { where('classroom_id = ? OR classroom_id IS NULL', classroom_id) }
  scope :by_student, lambda { |student_name|
    joins(:students).where(
      "(unaccent(students.name) ILIKE unaccent(:student_name) or
        unaccent(students.social_name) ILIKE unaccent(:student_name))",
      student_name: "%#{student_name}%"
    )
  }
  scope :by_discipline_id, lambda { |discipline_id|
    joins(:disciplines).where(absence_justifications_disciplines: { discipline_id: discipline_id })
  }
  scope :by_disciplines, lambda { |discipline_ids|
    joins(:disciplines).where(absence_justifications_disciplines: { discipline_id: [discipline_ids] })
  }
  scope :by_student_id, lambda { |student_id|
    joins(:students).where(absence_justifications_students: { student_id: student_id })
  }
  scope :by_date_range, lambda { |absence_date, absence_date_end|
    where('(NOT (absence_date > ? OR absence_date_end < ?))', absence_date_end.to_date, absence_date.to_date)
  }
  scope :by_unity, ->(unity_id) { where(unity_id: [unity_id, nil]) }
  scope :by_school_calendar, lambda { |school_calendar|
    where('school_calendar_id = ? OR school_calendar_id IS NULL', school_calendar)
  }
  scope :by_date, ->(date) { by_date_query(date) }
  scope :by_school_calendar_report, ->(school_calendar) { where(school_calendar: school_calendar) }
  scope :by_author, lambda { |author_type, current_user_id|
    if author_type == AbsenceJustificationAuthors::MY_JUSTIFICATIONS
      where(user_id: current_user_id)
    else
      where.not(user_id: current_user_id)
    end
  }
  scope :by_period, ->(period) { where(period: period) }

  private

  def self.by_date_query(date)
    date = date.to_date
    where(
      AbsenceJustification.arel_table[:absence_date]
      .lteq(date)
      .and(AbsenceJustification.arel_table[:absence_date_end].gteq(date))
    )
  end

  def no_retroactive_dates
    return if absence_date.nil? || absence_date_end.nil?

    return if absence_date <= absence_date_end

    errors.add(:absence_date, :not_greater_than_final)
    errors.add(:absence_date_end, :not_less_than_initial)
  end

  # TODO: release-absence-justification
  # - [ ] Remover vínculo com professor
  # - [ ] Remover vínculo com disciplina
  def period_absence
    return if absence_date.blank? || absence_date_end.blank?

    student_ids.each do |student_id|
      absence_justifications = AbsenceJustification.by_classroom(classroom)
                                                   .by_student_id(student_id)
                                                   .by_date_range(absence_date, absence_date_end)
                                                   .by_teacher(teacher_id)

      if frequence_type_by_discipline?
        absence_justifications = absence_justifications.by_disciplines(discipline_ids)
      end

      absence_justifications = absence_justifications.where.not(id: id) if persisted?

      next if absence_justifications.blank?

      errors.add(:base, :discipline_period_absence) if frequence_type_by_discipline?

      unless frequence_type_by_discipline?
        errors.add(:base, :general_period_absence, teacher: absence_justifications.first.teacher.name)
      end

      errors.add(:absence_date, :taken)
      errors.add(:absence_date_end, :taken)

      break
    end
  end

  def frequence_type_by_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      self.validation_type = :destroy
      valid?
      forbidden_error = I18n.t('errors.messages.not_allowed_to_post_in_date')
      !(errors[:absence_date_end].include?(forbidden_error) || errors[:absence_date].include?(forbidden_error))
    end
  end

  def remove_attachments
    absence_justification_attachments.each(&:destroy)
  end

  def at_least_one_student
    errors.add(:students, :at_least_one_student) if student_ids.blank?
  end

  def at_least_one_discipline
    errors.add(:disciplines, :at_least_one_discipline) if discipline_ids.blank?
  end

  private_class_method :by_date_query
end
