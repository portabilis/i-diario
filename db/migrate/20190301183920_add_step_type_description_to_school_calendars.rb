class AddStepTypeDescriptionToSchoolCalendars < ActiveRecord::Migration
  def change
    add_column :school_calendars, :step_type_description, :string
  end
end
