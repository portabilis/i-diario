class SchoolCalendarClassroom < ActiveRecord::Base
  belongs_to :school_calendar
  belongs_to :classroom

  has_many :classroom_steps, -> { order(:start_at) }, class_name: 'SchoolCalendarClassroomStep', dependent: :destroy

  accepts_nested_attributes_for :classroom_steps, reject_if: :all_blank, allow_destroy: true

  scope :by_classroom, lambda { |classroom_id| where(classroom_id: classroom_id)   }
  scope :by_classroom_api_code, lambda { |api_code| joins(:classroom).where(classrooms: { api_code: api_code })   }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id)   }
  scope :ordered_by_grade, -> { joins(:classroom).joins('inner join grades on (classrooms.grade_id = grades.id)').order('grades.course_id')   }
  scope :ordered_by_description, -> { joins(:classroom).order('classrooms.description')   }

  def classroom_step(date)
    classroom_steps.all.started_after_and_before(date).first
  end

  def posting_classroom_step(date)
    classroom_steps.all.posting_date_after_and_before(date).first
  end

  def school_term(date)
    school_terms = { 4 => Bimesters, 3 => Trimesters, 2 => Semesters }

    index_of_step = classroom_steps.find_index(classroom_step(date))

    school_term = school_terms[classroom_steps.count]
    school_term.key_for(index_of_step)
  end
end
