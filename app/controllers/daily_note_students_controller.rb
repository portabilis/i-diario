class DailyNoteStudentsController < ApplicationController

  respond_to :json, only: [:index, :old_notes]

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
end
