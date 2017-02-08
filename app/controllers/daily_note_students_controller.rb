class DailyNoteStudentsController < ApplicationController

  respond_to :json, only: [:index, :old_notes, :dependence]

  def index
    @daily_note_students = apply_scopes(DailyNoteStudent).ordered

    respond_with @daily_note_students
  end

  def old_notes
    return unless params[:classroom_id] && params[:discipline_id] && params[:school_calendar_step_id] && params[:student_id]

    school_calendar_step = SchoolCalendarStep.find(params[:school_calendar_step_id])

    daily_note_students = DailyNoteStudent.by_discipline_id(params[:discipline_id])
                                           .by_student_id(params[:student_id])
                                           .by_test_date_between(school_calendar_step.start_at, school_calendar_step.end_at)
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

  def old_notes_classroom_steps
    return unless params[:classroom_id] && params[:discipline_id] && params[:school_calendar_classroom_step_id] && params[:student_id]

    school_calendar_classroom_step = SchoolCalendarClassroomStep.find(params[:school_calendar_classroom_step_id])

    daily_note_students = DailyNoteStudent.by_discipline_id(params[:discipline_id])
                                           .by_student_id(params[:student_id])
                                           .by_test_date_between(school_calendar_classroom_step.start_at, school_calendar_classroom_step.end_at)
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
    render json: @old_notes
  end

  def dependence
    @daily_note_students = apply_scopes(DailyNoteStudent).ordered

    @students = []
    @normal_students = []
    @dependence_students = []

    @daily_note_students.each do |note_student|
      classroom = note_student.daily_note.classroom
      discipline = note_student.daily_note.discipline
      student_enrollment = StudentEnrollment.by_classroom(classroom).by_discipline(discipline).by_student(note_student.student_id).active.first
      note_student.dependence = student_has_dependence?(student_enrollment, discipline)

      @normal_students << note_student unless note_student.dependence
      @dependence_students << note_student if note_student.dependence
    end

    sequence = 0
    @normal_students.each do |note_student|
      sequence += 1
      @students << {
        sequence: sequence,
        id: note_student.student_id,
        name: note_student.student.name,
        note: note_student.note,
        dependence: note_student.dependence
      }
    end

    sequence = 0
    @dependence_students.each do |note_student|
      sequence += 1
      @students << {
        sequence: sequence,
        id: note_student.student_id,
        name: note_student.student.name,
        note: note_student.note,
        dependence: note_student.dependence
      }
    end

    respond_with @students
  end

  private


  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end
end
