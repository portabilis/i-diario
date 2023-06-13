class AddPostingDatesToSchoolCalendarSteps < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_steps, :start_date_for_posting, :date
    add_column :school_calendar_steps, :end_date_for_posting, :date
  end
end
