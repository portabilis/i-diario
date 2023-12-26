class AddFieldsToSchoolCalendarEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_events, :coverage, :string, default: 'by_unity', null: false
    add_column :school_calendar_events, :grade_id, :integer, index: true
    add_column :school_calendar_events, :classroom_id, :integer, index: true
    add_foreign_key :school_calendar_events, :grades
    add_foreign_key :school_calendar_events, :classrooms
  end
end
