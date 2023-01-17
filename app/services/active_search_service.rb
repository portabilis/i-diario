class ActiveSearchService

  def initialize(active_search, options = { note: nil })
    @active_search = active_search
    @options = options
  end

  def daily_note
    student = @active_search.student_enrollment.student
    start_date = @active_search.start_date
    end_date = @active_search.end_date.nil? ? Date.today : @active_search.end_date

    daily_note_students = DailyNoteStudent.by_test_date_between(start_date, end_date)
                                          .by_student_id(student)

    daily_note_students.each do |daily_note_student|
      daily_note_student.update(note: @options[:note])
    end
  end
end
