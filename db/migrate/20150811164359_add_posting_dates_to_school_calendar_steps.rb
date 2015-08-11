class AddPostingDatesToSchoolCalendarSteps < ActiveRecord::Migration
  def change
    add_column :school_calendar_steps, :start_date_for_posting, :date
    add_column :school_calendar_steps, :end_date_for_posting, :date
  end
end
