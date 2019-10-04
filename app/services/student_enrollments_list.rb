class StudentEnrollmentsList
  SEARCH_TYPES = [
    :by_date, :by_date_range
  ].freeze

  def initialize(params)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @date = params.fetch(:date, nil)
    @start_at = params.fetch(:start_at, nil)
    @end_at = params.fetch(:end_at, nil)
    @search_type = params.fetch(:search_type, :by_date)
    @show_inactive = params.fetch(:show_inactive, true)
    @show_inactive_outside_step = params.fetch(:show_inactive_outside_step, true)
    @score_type = params.fetch(:score_type, StudentEnrollmentScoreTypeFilters::BOTH) || StudentEnrollmentScoreTypeFilters::BOTH
    @opinion_type = params.fetch(:opinion_type, nil)
    @with_recovery_note_in_step = params.fetch(:with_recovery_note_in_step, false)
    @include_date_range = params.fetch(:include_date_range, false)
    @period = params.fetch(:period, nil)
    ensure_has_valid_params

    if search_type == :by_year && params[:year].blank?
      classroom = Classroom.find(@classroom)
      @year = classroom.year
    end

    adjust_date_range_by_year if opinion_type_by_year?
  end

  def student_enrollments
    fetch_student_enrollments
  end

  private

  attr_accessor :classroom, :discipline, :year, :date, :start_at, :end_at, :search_type, :show_inactive,
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
    students_enrollments ||= StudentEnrollment.by_classroom(classroom)
                                              .by_discipline(discipline)
                                              .by_score_type(score_type, classroom)
                                              .joins(:student)
                                              .includes(:student)
                                              .includes(:dependences)
                                              .active

    if include_date_range
      students_enrollments = students_enrollments.includes(:student_enrollment_classrooms)
                                                 .by_date_range(start_at, end_at)
                                                 .by_date_not_before(start_at)
    end

    students_enrollments = students_enrollments.by_opinion_type(opinion_type, classroom) if opinion_type
    students_enrollments = students_enrollments.with_recovery_note_in_step(step, discipline) if with_recovery_note_in_step

    students_enrollments = reject_duplicated_students(students_enrollments)

    students_enrollments = remove_not_displayable_students(students_enrollments)

    students_enrollments = order_by_sequence_and_name(students_enrollments)

    students_enrollments
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
        unique_student_enrollments << student_enrollment if show_inactive_outside_step || student_active?(student_enrollment)
      end
    end
    unique_student_enrollments.uniq
  end

  def student_active?(student_enrollment)
    enrollments_on_period = StudentEnrollment.where(id: student_enrollment)
                                             .by_classroom(classroom)
    if search_type == :by_date
      enrollments_on_period = enrollments_on_period.by_date(date)
    elsif search_type == :by_date_range
      enrollments_on_period = enrollments_on_period.by_date_range(start_at, end_at)
    elsif search_type == :by_year
      enrollments_on_period = enrollments_on_period.by_year(year)
    end

    enrollments_on_period.active.any?
  end

  def student_displayable_as_inactive?(student_enrollment)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(classroom)
                     .by_discipline(discipline)
                     .active
                     .show_as_inactive
                     .any?
  end

  def remove_not_displayable_students(students_enrollments)
    students_enrollments.select { |student_enrollment|
      student_active?(student_enrollment) ||
        (student_displayable_as_inactive?(student_enrollment) && show_inactive)
    }
  end

  def step
    @step ||= begin
      step_date = date || start_at
      StepsFetcher.new(Classroom.find(classroom)).step_by_date(step_date)
    end
  end

  def adjust_date_range_by_year
    school_calendar = step.school_calendar
    @start_at = school_calendar.first_day
    @end_at = school_calendar.last_day
  end

  def opinion_type_by_year?
    [OpinionTypes::BY_YEAR, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(@opinion_type)
  end

  def order_by_sequence_and_name(students_enrollments)
    ids = students_enrollments.map(&:id)
    enrollments = StudentEnrollment.where(id: ids)
                                   .by_classroom(@classroom)

    enrollments = enrollments.by_period(period) if period
    enrollments = if search_type != :by_year
                    start_at = @start_at || @date
                    end_at = @end_at || @date

                    enrollments.by_date_range(start_at, end_at)
                  else
                    enrollments.by_year(year)
                  end

    enrollments.active
               .ordered
               .to_a
               .uniq
  end
end
