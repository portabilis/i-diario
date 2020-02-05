class AddThematicUnitToDisciplineLessonPlans < ActiveRecord::Migration
  def change
    add_column :discipline_lesson_plans, :thematic_unit, :string
  end
end
