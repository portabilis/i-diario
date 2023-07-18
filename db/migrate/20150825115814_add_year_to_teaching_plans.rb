class AddYearToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :teaching_plans, :year, :integer, null: true

    execute <<-SQL
      UPDATE teaching_plans SET year = 2015;
    SQL

    change_column :teaching_plans, :year, :integer, null: false
  end
end
