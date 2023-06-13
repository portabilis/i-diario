class AddAttachmentFileNameWithHash < ActiveRecord::Migration[4.2]
  def change
    add_column :absence_justification_attachments, :attachment_file_name_with_hash, :string
    add_column :teaching_plan_attachments, :attachment_file_name_with_hash, :string
    add_column :lesson_plan_attachments, :attachment_file_name_with_hash, :string
  end
end
