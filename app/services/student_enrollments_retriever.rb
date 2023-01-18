class StudentEnrollmentsRetriever
  SEARCH_TYPES = [
    :by_date, :by_date_range
  ].freeze

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @search_type = params.fetch(:search_type, :by_date)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @date = params.fetch(:date, nil)
    @start_at = params.fetch(:start_at, nil)
    @end_at = params.fetch(:ent_at, nil)

    ensure_has_valid_params
  end

  def call
    return if @classroom.blank? || @discipline.blank?

    student_enrollments ||= StudentEnrollment.by_classroom(@classroom)
                                             .by_discipline(@discipline)
                                             .joins(:student)
                                             .includes(:student)
                                             .includes(:dependences)
                                             .includes(:student_enrollment_classrooms)
                                             .active

  end

  private

  def ensure_has_valid_params
    if @search_type.eql?(:by_date)
      raise ArgumentError, 'Should define date argument on search by date' unless @date
    elsif @search_type.eql?(:by_date_range)
      raise ArgumentError, 'Should define @start_at or @end_at argument on search by date_range' unless @start_at || @end_at
    end
  end

end