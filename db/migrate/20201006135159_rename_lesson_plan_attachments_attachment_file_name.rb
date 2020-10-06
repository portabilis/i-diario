class RenameLessonPlanAttachmentsAttachmentFileName < ActiveRecord::Migration
  def change
    rename_column :lesson_plan_attachments, :attachment_file_name, :attachment
  end
end
