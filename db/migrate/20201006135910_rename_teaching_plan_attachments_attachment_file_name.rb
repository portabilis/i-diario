class RenameTeachingPlanAttachmentsAttachmentFileName < ActiveRecord::Migration
  def change
    rename_column :teaching_plan_attachments, :attachment_file_name, :attachment
  end
end
