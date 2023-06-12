class ChangeSchoolCalendarStepToAcceptNullOnConceptualExams < ActiveRecord::Migration[4.2]
  def change
    change_column_null :conceptual_exams, :school_calendar_step_id, true
  end
end
