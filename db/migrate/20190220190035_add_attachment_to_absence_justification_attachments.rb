class AddAttachmentToAbsenceJustificationAttachments < ActiveRecord::Migration[4.2]
  def self.up
    change_table :absence_justification_attachments do |t|
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
    end
  end

  def self.down
    remove_attachment :absence_justification_attachments, :attachment
  end
end
