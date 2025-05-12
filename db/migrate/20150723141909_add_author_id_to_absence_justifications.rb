class AddAuthorIdToAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    add_column :absence_justifications, :author_id, :integer
    add_index :absence_justifications, :author_id
    add_foreign_key :absence_justifications, :users, column: :author_id

    execute <<-SQL
      UPDATE absence_justifications
      SET author_id = (SELECT audits.user_id FROM audits
                       WHERE audits.auditable_id = absence_justifications.id and audits.auditable_type = 'AbsenceJustification' and audits.action = 'create' limit 1)
      WHERE absence_justifications.author_id IS NULL;
    SQL
  end
end

