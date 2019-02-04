class SchoolCalendarClassroom < ActiveRecord::Base
  acts_as_copy_target

  audited

  belongs_to :school_calendar
  belongs_to :classroom

  has_many :classroom_steps, -> { ordered }, class_name: 'SchoolCalendarClassroomStep', dependent: :destroy

  accepts_nested_attributes_for :classroom_steps, reject_if: :all_blank, allow_destroy: true

  scope :by_unity_id, ->(unity_id) { joins(:school_calendar).where(school_calendars: { unity_id: unity_id }) }
  scope :by_classroom, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_classroom_api_code, ->(api_code) { joins(:classroom).where(classrooms: { api_code: api_code }) }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_school_calendar_id, ->(school_calendar_id) { where(school_calendar_id: school_calendar_id) }
  scope :ordered_by_grade, lambda {
    joins(:classroom).joins('inner join grades on (classrooms.grade_id = grades.id)').order('grades.course_id')
  }
  scope :ordered_by_description, -> { joins(:classroom).order('classrooms.description') }

  validates :classroom, :school_calendar, presence: true

  SCHOOL_TERMS = { 4 => Bimesters, 3 => Trimesters, 2 => Semesters, 1 => Year }.freeze

  def classroom_step(date)
    classroom_steps.all.started_after_and_before(date).first
  end

  def posting_step(date)
    classroom_steps.all.posting_date_after_and_before(date).first
  end

  def school_term(date)
    school_step(classroom_step(date))
  end

  def school_step(step)
    index_of_step = classroom_steps.find_index(step)

    if (school_term = SCHOOL_TERMS[classroom_steps.size])
      school_term.key_for(index_of_step)
    end
  end

  def first_day
    classroom_steps.reorder(start_at: :asc).first.start_at
  end

  def last_day
    classroom_steps.reorder(start_at: :desc).first.end_at
  end
end
