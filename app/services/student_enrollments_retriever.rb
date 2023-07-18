class StudentEnrollmentsRetriever
  SEARCH_TYPES = [
    :by_date, :by_date_range, :by_year
  ].freeze

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @search_type = params.fetch(:search_type, :by_date)
    @classrooms = params.fetch(:classrooms)
    @disciplines = params.fetch(:disciplines)
    @date = params.fetch(:date, nil)
    @start_at = params.fetch(:start_at, nil)
    @end_at = params.fetch(:end_at, nil)
    @year = params.fetch(:year, nil)
    @grade = params.fetch(:grade, nil)
    @include_date_range = params.fetch(:include_date_range, nil)
    @period = params.fetch(:period, nil)
    @opinion_type = params.fetch(:opinion_type, nil)
    @with_recovery_note_in_step = params.fetch(:with_recovery_note_in_step, nil)
    @score_type = params.fetch(:score_type, StudentEnrollmentScoreTypeFilters::BOTH)
    @classroom_grades = params.fetch(:classrooms_grade_ids, nil)

    ensure_has_valid_search_params
  end

  def call
    return if classrooms.blank? || disciplines.blank?

    student_enrollments ||= StudentEnrollment.by_classroom(classrooms)
                                             .by_discipline(disciplines)
                                             .by_score_type(score_type, classrooms)
                                             .joins(:student)
                                             .includes(:student)
                                             .includes(:dependences)
                                             .includes(:student_enrollment_classrooms)
                                             .active

    student_enrollments = student_enrollments.by_classroom_grades(classroom_grades) if classroom_grades
    student_enrollments = student_enrollments.by_grade(grade) if grade
    student_enrollments = student_enrollments.by_period(period) if period
    student_enrollments = student_enrollments.by_opinion_type(opinion_type, classrooms) if opinion_type
    student_enrollments = student_enrollments.with_recovery_note_in_step(step, discipline) if with_recovery_note_in_step
    student_enrollments = search_by_dates(student_enrollments) if include_date_range

    student_enrollments = search_by_search_type(student_enrollments)
    student_enrollments = search_by_status_attending(student_enrollments)
    student_enrollments = order_by_name_and_sequence(student_enrollments)

    student_enrollments
  end

  private

  attr_accessor :classrooms, :disciplines, :year, :date, :start_at, :end_at, :search_type, :classroom_grades,
                :include_date_range, :grade, :period, :opinion_type, :with_recovery_note_in_step, :score_type

  def ensure_has_valid_search_params
    if search_type.eql?(:by_date)
      raise ArgumentError, 'Should define date argument on search by date' unless date
    elsif search_type.eql?(:by_date_range)
      raise ArgumentError, 'Should define start_at or end_at argument on search by date_range' unless start_at || end_at
    elsif search_type.eql?(:by_year)
      raise ArgumentError, 'Should define start_at or end_at argument on search by date_range' unless year
    end
  end

  def search_by_dates(student_enrollments)
    enrollment_in_date = student_enrollments.by_date_range(start_at, end_at).by_date_not_before(start_at)

    return student_enrollments unless enrollment_in_date.present?

    enrollment_in_date
  end

  def search_by_search_type(student_enrollments)
    return student_enrollments if include_date_range

    if search_type.eql?(:by_date)
      enrollments_on_period = student_enrollments.by_date(date)
    elsif search_type.eql?(:by_date_range)
      enrollments_on_period = student_enrollments.by_date_range(start_at, end_at)
    elsif search_type.eql?(:by_year)
      enrollments_on_period = student_enrollments.by_year(year)
    end

    enrollments_on_period
  end

  def order_by_name_and_sequence(student_enrollments)
    return student_enrollments if show_inactive_enrollments

    student_enrollments.ordered
  end

  def search_by_status_attending(student_enrollments)
    return student_enrollments if show_inactive_enrollments

    student_enrollments.status_attending
  end

  def show_inactive_enrollments
    @show_inactive_enrollments = GeneralConfiguration.first.show_inactive_enrollments
  end
end
