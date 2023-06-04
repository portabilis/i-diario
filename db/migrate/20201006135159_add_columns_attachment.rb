class AddColumnsAttachment < ActiveRecord::Migration[4.2]
  def change
    add_column :lesson_plan_attachments, :attachment, :string
    add_column :teaching_plan_attachments, :attachment, :string
    add_column :absence_justification_attachments, :attachment, :string
  end
end
