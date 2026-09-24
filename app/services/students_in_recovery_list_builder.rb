class StudentsInRecoveryListBuilder
  attr_reader :enrollments, :classroom, :discipline, :step, :number_of_decimal_places,
              :active_enrollment_ids, :dependencies, :exemptions, :active_search_enrollment_ids

  def initialize(configuration:, classroom:, discipline:, step:, date:, number_of_decimal_places:)
    @configuration = configuration
    @classroom = classroom
    @discipline = discipline
    @step = step
    @date = date
    @number_of_decimal_places = number_of_decimal_places
  end

  def call
    students_in_recovery = fetch_students_in_recovery
    @enrollments = students_in_recovery.map { |student_in_recovery| student_in_recovery[:student_enrollment] }

    student_situations = StudentSituationsFetcher.call(
      enrollment_ids: @enrollments.map(&:id),
      classroom: @classroom,
      discipline: @discipline,
      step_number: @step&.to_number,
      date: @date
    )

    @dependencies = student_situations[:dependencies]
    @exemptions = student_situations[:exemptions]
    @active_search_enrollment_ids = student_situations[:enrollments_in_active_search]
    @active_enrollment_ids = student_situations[:active_on_date_ids]

    self
  end

  private

  def fetch_students_in_recovery
    StudentsInRecoveryFetcher.new(
      @configuration,
      @classroom.id,
      @discipline.id,
      @step.id,
      @date.to_s
    ).fetch
  end
end
