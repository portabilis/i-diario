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
    ensure_has_valid_params
  end

  def student_enrollments
    fetch_student_enrollments
  end

  private

  attr_accessor :classroom, :discipline, :date, :start_at, :end_at, :search_type, :show_inactive, :show_inactive_outside_step, :score_type, :opinion_type

  def ensure_has_valid_params
    if search_type == :by_date
      raise ArgumentError, "Should define date argument on search by date" unless date
    elsif search_type == :by_date_range
      raise ArgumentError, "Should define start_at and end_at arguments on search by date range" unless start_at || end_at
    end
  end

  def fetch_student_enrollments
    students_enrollments ||= StudentEnrollment.by_classroom(classroom)
                                              .by_discipline(discipline)
                                              .by_score_type(score_type, classroom)
                                              .includes(:student)
                                              .includes(:dependences)
                                              .active
                                              .ordered
    students_enrollments = students_enrollments.by_opinion_type(opinion_type, classroom) if opinion_type

    students_enrollments = reject_duplicated_students(students_enrollments)
    students_enrollments = remove_not_displayable_students(students_enrollments)
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
    if search_type == :by_date
      student_active_on_date?(student_enrollment)
    elsif search_type == :by_date_range
      student_active_on_date_range?(student_enrollment)
    end
  end

  def student_active_on_date?(student_enrollment)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(classroom)
                     .by_date(date)
                     .active
                     .any?
  end

  def student_active_on_date_range?(student_enrollment)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(classroom)
                     .by_date_range(start_at, end_at)
                     .active
                     .any?
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
    students_enrollments.reject do |student_enrollment|
      if search_type == :by_date
        (!student_active_on_date?(student_enrollment) && !student_displayable_as_inactive?(student_enrollment)) ||
        (student_displayable_as_inactive?(student_enrollment) && !show_inactive)
      elsif search_type == :by_date_range
        (!student_active_on_date_range?(student_enrollment) && !student_displayable_as_inactive?(student_enrollment)) ||
        (student_displayable_as_inactive?(student_enrollment) && !show_inactive)
      end
    end
  end
end
