class AddThematicUnitToDisciplineTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :discipline_teaching_plans, :thematic_unit, :string
  end
end
