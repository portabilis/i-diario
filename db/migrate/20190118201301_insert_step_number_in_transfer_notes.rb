class InsertStepNumberInTransferNotes < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE transfer_notes
         SET step_number = (
           SELECT COALESCE(MAX(step.step_number), 0)
             FROM step_by_classroom(
                    transfer_notes.classroom_id,
                    transfer_notes.recorded_at
                  ) AS step
         );
    SQL
  end
end
