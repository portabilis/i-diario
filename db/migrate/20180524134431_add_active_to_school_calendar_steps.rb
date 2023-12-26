class AddActiveToSchoolCalendarSteps < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_steps, :active, :boolean, default: true
  end
end
