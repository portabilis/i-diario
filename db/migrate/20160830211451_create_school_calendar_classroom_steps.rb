class CreateSchoolCalendarClassroomSteps < ActiveRecord::Migration[4.2]
  def change
    create_table :school_calendar_classroom_steps do |t|
      t.references :school_calendar_classroom, index: {name: "index_school_calendar_classroom"}, foreign_key: true
      t.date :start_at
      t.date :end_at
      t.date :start_date_for_posting
      t.date :end_date_for_posting

      t.timestamps null: false
    end
  end
end
