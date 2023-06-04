class RemoveAbsenceJustificationsWithoutStudents < ActiveRecord::Migration[4.2]
  class MigrationAbsenceJustification < ActiveRecord::Base
    self.table_name = :absence_justifications
  end

  class MigrationAbsenceJustificationDiscipline < ActiveRecord::Base
    self.table_name = :absence_justifications_disciplines
  end

  class MigrationAbsenceJustificationAttachment < ActiveRecord::Base
    self.table_name = :absence_justification_attachments
  end

  def change
    MigrationAbsenceJustification.where(
      'id NOT IN (SELECT DISTINCT(absence_justification_id) FROM absence_justifications_students)'
    ).each do |absence_justification|
      MigrationAbsenceJustificationDiscipline.where(absence_justification_id: absence_justification.id)
                                             .each do |absence_justifications_discipline|
        absence_justifications_discipline.without_auditing do
          absence_justifications_discipline.destroy
        end
      end

      MigrationAbsenceJustificationAttachment.where(absence_justification_id: absence_justification.id)
                                             .each(&:destroy)
      absence_justification.without_auditing do
        absence_justification.destroy
      end
    end
  end
end
