class StudentEnrollmentsRetriever

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @search_type = params.fetch(:search_type, :by_date)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @date = params.fetch(:date, nil)
    @score_type = params.fetch(:score_type, StudentEnrollmentScoreTypeFilters::BOTH)
  end

  def call
    students_enrollments ||= StudentEnrollment.by_classroom(@classroom)
                                              .by_discipline(@discipline)
                                              .by_score_type(@score_type, @classroom)
                                              .joins(:student)
                                              .includes(:student)
                                              .includes(:dependences)
                                              .includes(:student_enrollment_classrooms)
                                              .active
    # chama outros metodos
  end

  private

  # def outros
  #
  # end

end