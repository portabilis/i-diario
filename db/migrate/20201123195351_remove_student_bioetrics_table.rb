class RemoveStudentBioetricsTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :student_biometrics
  end
end
