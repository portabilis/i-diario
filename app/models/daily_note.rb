class DailyNote < ActiveRecord::Base
  acts_as_copy_target

  acts_as_paranoid

  audited
  has_associated_audits

  include Audit

  belongs_to :avaliation

  has_one :daily_note_status
  has_many :students, -> { includes(:student).order('students.name') }, class_name: 'DailyNoteStudent', dependent: :destroy

  accepts_nested_attributes_for :students, allow_destroy: true

  has_enumeration_for :status, with: DailyNoteStatuses, create_helpers: true

  validates :unity, presence: true
  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :avaliation, presence: true

  validate :avaliation_date_must_be_less_than_or_equal_to_today

  before_destroy :ensure_not_has_avaliation_recovery

  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_unity_id, lambda { |unity_id| joins(:avaliation).merge(Avaliation.by_unity_id(unity_id))}
  scope :by_classroom_id, lambda { |classroom_id| joins(:avaliation).merge(Avaliation.by_classroom_id(classroom_id))}
  scope :by_discipline_id, lambda { |discipline_id| joins(:avaliation).merge(Avaliation.by_discipline_id(discipline_id))}
  scope :exclude_discipline_ids, lambda { |discipline_ids| joins(:avaliation).merge(Avaliation.exclude_discipline_ids(discipline_ids))}
  scope :by_test_date_between, lambda { |start_at, end_at| includes(:avaliation, students: :student).where('avaliations.test_date': start_at.to_date..end_at.to_date) }
  scope :by_avaliation_id, lambda { |avaliation_id| joins(:avaliation).where(avaliation: avaliation_id) }
  scope :by_school_calendar_step_id, lambda { |school_calendar_step_id| joins(:avaliation).merge(Avaliation.by_school_calendar_step(school_calendar_step_id)) }
  scope :by_school_calendar_classroom_step_id, lambda { |school_calendar_classroom_step_id| joins(:avaliation).merge(Avaliation.by_school_calendar_classroom_step(school_calendar_classroom_step_id))   }
  scope :with_daily_note_students, lambda { |with_daily_note_student| with_daily_note_students_query(with_daily_note_student) }
  scope :by_status, lambda { |status| joins(:daily_note_status).merge(DailyNoteStatus.by_status(status)) }
  scope :active, -> { joins(:students).merge(DailyNoteStudent.active) }
  scope :not_including_classroom_id, lambda { |classroom_id| joins(:avaliation).merge(Avaliation.not_including_classroom_id(classroom_id)) }

  scope :order_by_student_name, -> { order('students.name') }
  scope :order_by_avaliation_test_date, -> { order('avaliations.test_date') }
  scope :order_by_avaliation_test_date_desc, -> { order('avaliations.test_date DESC') }
  scope :order_by_sequence, -> { joins(students: [student: :student_enrollments]).merge(StudentEnrollment.ordered) }

  delegate :status, to: :daily_note_status, prefix: false, allow_nil: true
  delegate :classroom, :classroom_id, :discipline, :discipline_id, to: :avaliation, allow_nil: true
  delegate :unity, :unity_id, to: :classroom, allow_nil: true
  delegate :test_date, :school_calendar, to: :avaliation

  def current_step
    return unless avaliation.school_calendar

    school_calendar_classroom = avaliation.school_calendar.classrooms.find_by_classroom_id(classroom.id)

    return school_calendar_classroom.classroom_step(test_date) if school_calendar_classroom.present?

    avaliation.school_calendar.step(test_date)
  end

  private

  def self.by_teacher_id_query(teacher_id)
    joins(
      arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
        .on(
          TeacherDisciplineClassroom.arel_table[:classroom_id]
            .eq(DailyNote.arel_table[:classroom_id])
            .and(
              TeacherDisciplineClassroom.arel_table[:discipline_id]
                .eq(DailyNote.arel_table[:discipline_id])
            )
        )
        .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id)
      .and(TeacherDisciplineClassroom.arel_table[:active].eq('t')))
  end

  def ensure_not_has_avaliation_recovery
    if AvaliationRecoveryDiaryRecord.find_by_avaliation_id(avaliation)
      errors.add(:base)
      false
    end
  end

  def avaliation_date_must_be_less_than_or_equal_to_today
    return unless avaliation

    if avaliation.test_date > Time.zone.today
      errors.add(:avaliation, :must_be_less_than_or_equal_to_today)
    end
  end

  def self.with_daily_note_students_query(with_daily_notes)
    if with_daily_notes
      DailyNote.where('daily_notes.id in(select daily_note_id from daily_note_students where daily_note_students.note is not null)')
    else
      DailyNote.where('daily_notes.id not in(select daily_note_id from daily_note_students where daily_note_students.note is not null)')
    end
  end
end
