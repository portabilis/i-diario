class CreateStudentBiometrics < ActiveRecord::Migration[4.2]
  def change
    create_table :student_biometrics do |t|
      t.integer :student_id, null: false, index: true
      t.integer :biometric_type, null: false
      t.text :biometric, null: false
    end
    add_foreign_key :student_biometrics, :students
  end
end
