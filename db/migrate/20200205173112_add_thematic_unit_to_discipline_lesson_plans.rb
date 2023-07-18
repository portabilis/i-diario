class AddThematicUnitToDisciplineLessonPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :discipline_lesson_plans, :thematic_unit, :string
  end
end
