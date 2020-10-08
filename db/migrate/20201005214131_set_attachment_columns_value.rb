class SetAttachmentColumnsValue < ActiveRecord::Migration
  def change
    klasses = [TeachingPlanAttachment, AbsenceJustificationAttachment, LessonPlanAttachment]
    klasses.each do |klass|
      klass.find_each do |obj|
        obj.update_columns(attachment_file_name_with_hash: obj.attachment.path.split('/').last)
      end
    end
  end
end
