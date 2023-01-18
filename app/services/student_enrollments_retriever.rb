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

    ensure_has_valid_search_params
  end

  def call
    return if @classrooms.blank? || @disciplines.blank?

    student_enrollments ||= StudentEnrollment.by_classroom(@classrooms)
                                             .by_discipline(@disciplines)
                                             .joins(:student)
                                             .includes(:student)
                                             .includes(:dependences)
                                             .includes(:student_enrollment_classrooms)
                                             .active

    search_by_search_type(student_enrollments)
    # remove_not_displayable_classrooms(student_enrollments)
    order_by_name_and_sequence(student_enrollments)
  end

  private

  def ensure_has_valid_search_params
    if @search_type.eql?(:by_date)
      raise ArgumentError, 'Should define date argument on search by date' unless @date
    elsif @search_type.eql?(:by_date_range)
      raise ArgumentError, 'Should define @start_at or @end_at argument on search by date_range' unless @start_at || @end_at
    elsif @search_type.eql?(:by_year)
      raise ArgumentError, 'Should define @start_at or @end_at argument on search by date_range' unless @year
    end
  end

  def search_by_search_type(student_enrollments)
    if @search_type.eql?(:by_date)
      enrollments_on_period = student_enrollments.by_date(@date)
    elsif  @search_type.eql?(:by_date_range)
      enrollments_on_period = student_enrollments.by_date_range(@start_at, @end_at)
    elsif  @search_type.eql?(:by_year)
      enrollments_on_period = student_enrollments.by_year(@year)
    end

    enrollments_on_period
  end

  def order_by_name_and_sequence(student_enrollments)
    student_enrollments.ordered unless show_inactive_enrollments
  end

  def show_inactive_enrollments
    @show_inactive_enrollments ||= GeneralConfiguration.first.show_inactive_enrollments
  end
end
