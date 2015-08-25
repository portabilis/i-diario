class RemoveSchoolCalendarStepIdFromTeachingPlans < ActiveRecord::Migration
  def change
    remove_column :teaching_plans, :school_calendar_step_id
  end
end
