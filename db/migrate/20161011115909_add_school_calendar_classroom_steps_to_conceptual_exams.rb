class AddSchoolCalendarClassroomStepsToConceptualExams < ActiveRecord::Migration[4.2]
  def change
    add_reference :conceptual_exams, :school_calendar_classroom_step, index: true, foreign_key: true
  end
end
