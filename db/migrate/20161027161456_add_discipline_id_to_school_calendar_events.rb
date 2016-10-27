class AddDisciplineIdToSchoolCalendarEvents < ActiveRecord::Migration
  def change
    add_column :school_calendar_events, :discipline_id, :integer, index: true
  end
end
