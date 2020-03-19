class AddThematicUnitToDisciplineTeachingPlans < ActiveRecord::Migration
  def change
    add_column :discipline_teaching_plans, :thematic_unit, :string
  end
end
