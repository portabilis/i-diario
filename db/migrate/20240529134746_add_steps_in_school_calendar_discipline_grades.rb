class AddStepsInSchoolCalendarDisciplineGrades < ActiveRecord::Migration[5.0]
  def change
    add_column :school_calendar_discipline_grades, :steps, :string
  end
end
