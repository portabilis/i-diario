class StudentEnrollmentClassroomsRetriever
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
    @score_type = params.fetch(:score_type, nil)

    ensure_has_valid_search_params
  end

  def call
    return if classrooms.blank? || disciplines.blank?

    enrollment_classrooms ||= StudentEnrollmentClassroom.by_classroom(classrooms)
                                                        .by_discipline(disciplines)
                                                        .by_score_type(score_type, classrooms)
                                                        .joins(student_enrollment: :student)
                                                        .includes(student_enrollment: :student)
                                                        .includes(student_enrollment: :dependences)
                                                        .active

    # enrollment_classrooms = enrollment_classrooms.by_grade(grade) if grade
    # enrollment_classrooms = enrollment_classrooms.by_period(period) if period
    # enrollment_classrooms = enrollment_classrooms.by_opinion_type(opinion_type, classrooms) if opinion_type
    # enrollment_classrooms = enrollment_classrooms.with_recovery_note_in_step(step, discipline) if with_recovery_note_in_step
    # enrollment_classrooms = search_by_dates(enrollment_classrooms) if include_date_range
    #
    # enrollment_classrooms = search_by_search_type(enrollment_classrooms)
    # enrollment_classrooms = search_by_status_attending(enrollment_classrooms)
    # enrollment_classrooms = order_by_name_and_sequence(enrollment_classrooms)

    enrollment_classrooms
  end

  private

  attr_accessor :classrooms, :disciplines, :year, :date, :start_at, :end_at, :search_type,
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

  def search_by_dates(enrollment_classrooms)
    enrollment_in_date = enrollment_classrooms.by_date_range(start_at, end_at).by_date_not_before(start_at)

    enrollment_classroomsunless enrollment_in_date.present?
  end

  def search_by_search_type(enrollment_classrooms)
    return enrollment_classrooms if include_date_range

    if search_type.eql?(:by_date)
      enrollments_on_period = enrollment_classrooms.by_date(date)
    elsif search_type.eql?(:by_date_range)
      enrollments_on_period = enrollment_classrooms.by_date_range(start_at, end_at)
    elsif search_type.eql?(:by_year)
      enrollments_on_period = enrollment_classrooms.by_year(year)
    end

    enrollments_on_period
  end

  def order_by_name_and_sequence(enrollment_classrooms)
    return enrollment_classrooms if show_inactive_enrollments

    enrollment_classrooms.ordered
  end

  def search_by_status_attending(enrollment_classrooms)
    return enrollment_classrooms if show_inactive_enrollments

    enrollment_classrooms.status_attending
  end

  def show_inactive_enrollments
    @show_inactive_enrollments = GeneralConfiguration.first.show_inactive_enrollments
  end
end
