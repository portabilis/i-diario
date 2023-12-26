class AddDiscardedAtToStudentBiometrics < ActiveRecord::Migration[4.2]
  def change
    add_column :student_biometrics, :discarded_at, :datetime
  end
end
