class ChangeSchoolCalendarStepToAcceptNullOnConceptualExams < ActiveRecord::Migration
  def change
    change_column_null :conceptual_exams, :school_calendar_step_id, true
  end
end
