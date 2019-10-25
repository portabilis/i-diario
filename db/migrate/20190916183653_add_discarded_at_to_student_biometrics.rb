class AddDiscardedAtToStudentBiometrics < ActiveRecord::Migration
  def change
    add_column :student_biometrics, :discarded_at, :datetime
  end
end
