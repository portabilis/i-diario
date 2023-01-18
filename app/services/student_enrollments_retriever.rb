class StudentEnrollmentsRetriever

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @search_type = params.fetch(:search_type, :by_date)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @date = params.fetch(:date, nil)

    ensure_has_valid_params
  end

  def call
    return if @classroom.blank? || @discipline.blank? || @search_type.blank?

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
    end
  end

end