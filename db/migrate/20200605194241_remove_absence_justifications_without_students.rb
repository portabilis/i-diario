class RemoveAbsenceJustificationsWithoutStudents < ActiveRecord::Migration
  class MigrationAbsenceJustification < ActiveRecord::Base
    self.table_name = :absence_justifications
  end

  def change
    MigrationAbsenceJustification.where(
      'id NOT IN (SELECT DISTINCT(absence_justification_id) FROM absence_justifications_students)'
    ).each(&:destroy)
  end
end
