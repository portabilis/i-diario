class StudentsInRecoveryListBuilder
  attr_reader :enrollments, :classroom, :discipline, :step, :number_of_decimal_places,
              :active_classroom_enrollment_ids, :classroom_enrollment_by_enrollment,
              :dependencies, :exemptions, :active_search_enrollment_ids

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
    enrollment_ids = @enrollments.map(&:id)

    @active_classroom_enrollment_ids = ActiveStudentsOnDate.call(
      student_enrollments: enrollment_ids,
      date: @date
    )
    @dependencies = StudentsInDependency.call(
      student_enrollments: enrollment_ids,
      disciplines: @discipline
    )
    @exemptions = StudentsExemptFromDiscipline.call(
      student_enrollments: enrollment_ids,
      discipline: @discipline,
      step: @step.to_number,
      classroom_id: @classroom.id
    )
    @active_search_enrollment_ids =
      ActiveSearch.new.enrollments_in_active_search?(enrollment_ids, @date)[@date] || []

    @classroom_enrollment_by_enrollment = students_in_recovery.each_with_object({}) do |student_in_recovery, hash|
      hash[student_in_recovery[:student_enrollment].id] = student_in_recovery[:student_enrollment_classroom].id
    end

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
