class AddAttachmentToAbsenceJustificationAttachments < ActiveRecord::Migration
  def self.up
    change_table :absence_justification_attachments do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :absence_justification_attachments, :attachment
  end
end
