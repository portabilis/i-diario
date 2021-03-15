class RemoveStudentBioetricsTable < ActiveRecord::Migration
  def change
    drop_table :student_biometrics
  end
end
