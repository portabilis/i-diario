class RenameAbsenceJustificationAttachmentsAttachmentFileName < ActiveRecord::Migration
  def change
    rename_column :absence_justification_attachments, :attachment_file_name, :attachment
  end
end
