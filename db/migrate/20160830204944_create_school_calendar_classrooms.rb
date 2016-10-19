class CreateSchoolCalendarClassrooms < ActiveRecord::Migration
  def change
    create_table :school_calendar_classrooms do |t|
      t.references :school_calendar, index: true, foreign_key: true
      t.references :classroom, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
