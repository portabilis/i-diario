class AddStepTypeDescriptionToSchoolCalendarClassrooms < ActiveRecord::Migration
  def change
    add_column :school_calendar_classrooms, :step_type_description, :string
  end
end
