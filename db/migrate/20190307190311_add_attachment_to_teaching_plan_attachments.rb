class AddAttachmentToTeachingPlanAttachments < ActiveRecord::Migration
  def self.up
    change_table :teaching_plan_attachments do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :teaching_plan_attachments, :attachment
  end
end
