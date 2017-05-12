class AddAttachmentAttachmentToLessonPlanAttachments < ActiveRecord::Migration
  def self.up
    change_table :lesson_plan_attachments do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :lesson_plan_attachments, :attachment
  end
end
