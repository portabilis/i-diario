class CreateSchoolCalendarDisciplineGrades < ActiveRecord::Migration[4.2]
  def change
    create_table :school_calendar_discipline_grades do |t|
      t.belongs_to :school_calendar
      t.belongs_to :discipline
      t.belongs_to :grade

      t.timestamps
    end
  end
end
