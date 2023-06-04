class AddSchoolTermTypeAndSchoolTermToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :teaching_plans, :school_term_type, :string, null: true
    add_column :teaching_plans, :school_term, :string, null: true

    execute <<-SQL
      UPDATE teaching_plans SET school_term_type = 'semester';
      UPDATE teaching_plans SET school_term = 'second';
    SQL

    change_column :teaching_plans, :school_term_type, :string, null: false
  end
end
