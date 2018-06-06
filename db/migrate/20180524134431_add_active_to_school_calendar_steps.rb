class AddActiveToSchoolCalendarSteps < ActiveRecord::Migration
  def change
    add_column :school_calendar_steps, :active, :boolean, default: true
  end
end
