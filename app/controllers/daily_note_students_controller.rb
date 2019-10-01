class DailyNoteStudentsController < ApplicationController
  respond_to :json, only: [:index, :old_notes, :dependence]

  def index
    @daily_note_students = apply_scopes(DailyNoteStudent).ordered

    respond_with @daily_note_students
  end

  def old_notes
    return unless params[:step_id].present? && params[:student_id].present?

    step = StepsFetcher.new(Classroom.find(params[:classroom_id])).step_by_id(params[:step_id])

    daily_note_students = DailyNoteStudent.by_discipline_id(params[:discipline_id])
                                          .by_student_id(params[:student_id])
                                          .by_test_date_between(step.start_at, step.end_at)
                                          .not_including_classroom_id(params[:classroom_id])
                                          .ordered

    @old_notes = []

    daily_note_students.each do |daily_note_student|
      @old_notes << {
        avaliation_description: daily_note_student.avaliation.description_to_teacher,
        note: daily_note_student.note,
        recovery_note: daily_note_student.recovery_note
      }
    end

    respond_with old_notes: @old_notes
  end

  def dependence
    @daily_note_students = apply_scopes(DailyNoteStudent).ordered

    @students = []
    @normal_students = []
    @dependence_students = []

    if @daily_note_students.any?
      daily_note = @daily_note_students.first.daily_note
      date_for_search = params[:search][:recorded_at].to_date

      student_enrollments = fetch_student_enrollments(daily_note.classroom, daily_note.discipline, date_for_search)

      student_enrollments.each do |student_enrollment|
        student = Student.find_by(id: student_enrollment.student_id)
        next unless student

        note_student = @daily_note_students.where(student_id: student.id).first ||
                       DailyNoteStudent.new(student: student)

        note_student.dependence = student_has_dependence?(student_enrollment, daily_note.discipline)
        note_student.active = student_active_on_date?(student_enrollment, daily_note.classroom, date_for_search)
        note_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, daily_note)

        @normal_students << note_student unless note_student.dependence
        @dependence_students << note_student if note_student.dependence
      end

      sequence = 0

      @normal_students.each do |note_student|
        sequence += 1

        @students << {
          sequence: sequence,
          id: note_student.student_id,
          name: note_student.student.to_s,
          note: note_student.note,
          dependence: note_student.dependence,
          exempted_from_discipline: note_student.exempted_from_discipline,
          active: note_student.active
        }
      end

      sequence = 0

      @dependence_students.each do |note_student|
        sequence += 1

        @students << {
          sequence: sequence,
          id: note_student.student_id,
          name: note_student.student.to_s,
          note: note_student.note,
          dependence: note_student.dependence,
          exempted_from_discipline: note_student.exempted_from_discipline,
          active: note_student.active
        }
      end
    end

    respond_with @students
  end

  private

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence.by_student_enrollment(student_enrollment)
                               .by_discipline(discipline)
                               .any?
  end

  def student_active_on_date?(student_enrollment, classroom, test_date)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(classroom)
                     .by_date(test_date)
                     .any?
  end

  def fetch_student_enrollments(classroom, discipline, date)
    StudentEnrollmentsList.new(
      classroom: classroom,
      discipline: discipline,
      date: date,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date
    ).student_enrollments
  end

  def student_exempted_from_discipline?(student_enrollment, daily_note)
    discipline_id = daily_note.discipline.id
    test_date = daily_note.avaliation.test_date
    step_number = daily_note.avaliation.school_calendar.step(test_date).to_number

    student_enrollment.exempted_disciplines.by_discipline(discipline_id)
                                           .by_step_number(step_number)
                                           .any?
  end
end
