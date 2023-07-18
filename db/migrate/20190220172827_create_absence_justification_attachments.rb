class CreateAbsenceJustificationAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :absence_justification_attachments do |t|
      t.references :absence_justification,
                   index: {
                     name: 'idx_absence_justification_attachs_on_absence_justification_id'
                   },
                   foreign_key: true

      t.timestamps null: false
    end
  end
end
