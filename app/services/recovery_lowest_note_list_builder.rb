class RecoveryLowestNoteListBuilder
  attr_reader :enrollments, :classroom, :discipline, :step,
              :dependencies, :exemptions,
              :active_search_enrollment_ids, :active_enrollment_ids,
              :sequence_by_enrollment

  def initialize(classroom:, discipline:, step:, date:, score_type:)
    @classroom = classroom
    @discipline = discipline
    @step = step
    @date = date
    @score_type = score_type
  end

  def call
    @enrollments = fetch_student_enrollments

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

    assign_display_sequence

    self
  end

  def notes_fetcher
    @notes_fetcher ||= StudentNotesInStepFetcher.new
  end

  private

  def fetch_student_enrollments
    StudentEnrollmentsList.new(
      classroom: @classroom.id,
      discipline: @discipline.id,
      search_type: :by_date,
      date: @date,
      score_type: @score_type
    ).student_enrollments
  end

  def assign_display_sequence
    normal_students = 0
    dependence_students = 0
    @sequence_by_enrollment = {}

    @enrollments.each do |enrollment|
      if @dependencies[enrollment.id].present?
        dependence_students += 1
        @sequence_by_enrollment[enrollment.id] = dependence_students
      else
        normal_students += 1
        @sequence_by_enrollment[enrollment.id] = normal_students
      end
    end
  end
end
