class StudentEnrollmentsList
  include Portabilis::ParamsHandler

  SEARCH_TYPES = [
    :by_date, :by_date_range
  ].freeze

  def initialize(params)
    fetch_params_to_attributes([
      { param: :classroom },
      { param: :discipline },
      { param: :date },
      { param: :start_at },
      { param: :end_at },
      { param: :opinion_type },
      { param: :search_type,  default: :by_date },
      { param: :show_inactive,  default: true },
      { param: :show_inactive_outside_step, default: true },
      { param: :with_recovery_note_in_step,  default: false },
      { param: :include_date_range,  default: false },
      { param: :period },
      { param: :score_type, default: StudentEnrollmentScoreTypeFilters::BOTH },
    ], params)

    ensure_has_valid_params
    adjust_date_range_by_year
  end

  def student_enrollments
    fetch_student_enrollments
  end

  private

  attr_accessor :classroom, :discipline, :date, :start_at, :end_at, :search_type, :show_inactive,
                :show_inactive_outside_step, :score_type, :opinion_type, :with_recovery_note_in_step,
                :include_date_range, :period

  def ensure_has_valid_params
    if search_type == :by_date
      raise ArgumentError, 'Should define date argument on search by date' unless date
    elsif search_type == :by_date_range
      raise ArgumentError, 'Should define start_at and end_at arguments on search by date range' unless start_at || end_at
    end
  end

  def fetch_student_enrollments
    student_enrollments = filtered_student_enrollments
    student_enrollments = reject_duplicated_students(student_enrollments)

    remove_not_displayable_students(student_enrollments)
  end

  def filtered_student_enrollments
    student_enrollments = active_student_enrollments.ordered

    if include_date_range
      student_enrollments = student_enrollments
          .includes(:student_enrollment_classrooms)
          .by_date_range(start_at, end_at)
          .by_date_not_before(start_at)
    end

    student_enrollments = student_enrollments.by_period(period) if period
    student_enrollments = student_enrollments.by_opinion_type(opinion_type, classroom) if opinion_type
    student_enrollments = student_enrollments.with_recovery_note_in_step(step, discipline) if with_recovery_note_in_step

    student_enrollments
  end

  def active_student_enrollments
    @active_student_enrollments ||= begin
      StudentEnrollment.by_classroom(classroom)
        .by_discipline(discipline)
        .by_score_type(score_type, classroom)
        .includes(:student)
        .includes(:dependences)
        .active
    end
  end

  def reject_duplicated_students(student_enrollments)
    unique_student_enrollments = []

    student_enrollments.each do |student_enrollment|
      student_enrollments_for_student = student_enrollments.by_student(student_enrollment.student_id).active

      if student_enrollments_for_student.count > 1
        any_active_enrollment = false
        student_enrollments_for_student.each do |student_enrollment_for_student|
          if student_active?(student_enrollment_for_student)
            unique_student_enrollments << student_enrollment_for_student
            any_active_enrollment = true
            break
          end
        end

        if !any_active_enrollment
          unique_student_enrollments << student_enrollments_for_student.show_as_inactive.first
        end
      else
        if show_inactive_outside_step || student_active?(student_enrollment)
          unique_student_enrollments << student_enrollment
        end
      end
    end

    unique_student_enrollments.uniq
  end

  def remove_not_displayable_students(student_enrollments)
    student_enrollments.select do |student_enrollment|
      student_active?(student_enrollment) || display_inactive_student?(student_enrollment)
    end
  end

  def student_active?(student_enrollment)
    enrollments_on_period = StudentEnrollment.where(id: student_enrollment)
                                             .by_classroom(classroom)
    if search_type == :by_date
      enrollments_on_period = enrollments_on_period.by_date(date)
    elsif search_type == :by_date_range
      enrollments_on_period = enrollments_on_period.by_date_range(start_at, end_at)
    end

    enrollments_on_period.active.any?
  end

  def display_inactive_student?(student_enrollment)
    show_inactive && student_displayable_as_inactive?(student_enrollment)
  end

  def student_displayable_as_inactive?(student_enrollment)
    active_student_enrollments.where(id: student_enrollment).show_as_inactive.any?
  end

  def step
    @step ||= begin
      step_date = date || start_at
      StepsFetcher.new(Classroom.find(classroom)).step_by_date(step_date)
    end
  end

  def adjust_date_range_by_year
    return if !opinion_type_by_year?

    school_calendar = step.school_calendar
    @start_at = school_calendar.first_day
    @end_at = school_calendar.last_day
  end

  def opinion_type_by_year?
    [OpinionTypes::BY_YEAR, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(@opinion_type)
  end
end
