class PopulateAttachments < ActiveRecord::Migration[4.2]
  def change
    execute(<<-SQL)
      update absence_justification_attachments
      set attachment = attachment_file_name_with_hash;

      update teaching_plan_attachments
      set attachment = attachment_file_name_with_hash;

      update lesson_plan_attachments
      set attachment = attachment_file_name_with_hash;
    SQL
  end
end
