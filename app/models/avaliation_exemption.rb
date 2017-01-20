class AvaliationExemption < ActiveRecord::Base
  belongs_to :avaliation
  belongs_to :student
  belongs_to :unity

  audited
  has_associated_audits

  include Audit

  validates :avaliation_id,
            :reason,
            :unity_id,
            :course_id,
            :grade_id,
            :classroom_id,
            :discipline_id,
            presence: true

  validates :school_calendar_step, presence: true, unless: :school_calendar_classroom_step
  validates :school_calendar_classroom_step, presence: true, unless: :school_calendar_step

  validates :student_id,
    presence: true,
    uniqueness: { scope: [:avaliation_id] }

  validate :ensure_no_score_for_avaliation

  delegate :unity_id, :discipline_id, :school_calendar_id, :classroom_id, :classroom, :discipline,
    to: :avaliation, prefix: false, allow_nil: true
  delegate :test_date, to: :avaliation, prefix: true, allow_nil: true
  delegate :grade_id, :grade, to: :classroom, prefix: false, allow_nil: true
  delegate :course_id, to: :grade, prefix: false, allow_nil: true

  scope :by_unity, lambda { |unity_id| joins(:avaliation).where( avaliations: { unity_id: unity_id } ) }
  scope :by_student, lambda { |student_id| where(student_id: student_id) }
  scope :by_avaliation, lambda { |avaliation_id| where(avaliation_id: avaliation_id) }
  scope :by_classroom, lambda { |classroom_id| joins(:avaliation).where(avaliations: { classroom_id: classroom_id } ) }
  scope :by_discipline, lambda { |discipline_id| joins(:avaliation).where(avaliations: { discipline_id: discipline_id } ) }

  scope :by_grade_description, lambda { |grade_description|
    joins(avaliation: [classroom: :grade])
    .where('grades.description ILIKE ?', "%#{grade_description}%" )
  }

  scope :by_classroom_description, lambda { |classroom_description|
    joins(avaliation: :classroom)
    .where('classrooms.description ILIKE ?', "%#{classroom_description}%" )
  }

  scope :by_student_name, lambda { |student_name|
    joins(:student)
    .where('students.name ILIKE ?', "%#{student_name}%" )
  }

  scope :by_avaliation_description, lambda { |avaliation_description|
    joins(:avaliation)
    .where('avaliations.description ILIKE ?', "%#{avaliation_description}%" )
  }

  scope :by_created_at, lambda { |created_at| where('avaliation_exemptions.created_at::DATE = ?', created_at.to_date) }

  def school_calendar_step
    school_calendar_step = SchoolCalendarStep
      .by_school_calendar_id(school_calendar_id)
      .started_after_and_before(avaliation_test_date)
      .first
      .try(:id)
    school_calendar_step
  end

  def school_calendar_classroom_step
    school_calendar_classroom_step = SchoolCalendarClassroomStep
      .by_school_calendar_id(school_calendar_id)
      .by_classroom(classroom)
      .started_after_and_before(avaliation_test_date)
      .first
      .try(:id)
    school_calendar_classroom_step
  end

  def ensure_no_score_for_avaliation
    daily_note_student = DailyNoteStudent
    .by_student_id(student_id)
    .by_avaliation(avaliation_id)
    .first

    if daily_note_student
      errors.add(:avaliation_id, :has_score_on_avaliation) unless daily_note_student.note.nil?
    end
  end
end
