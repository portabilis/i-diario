module ContentRecordHelper
  def content_record_destroy?(content_record)
    content_record.teacher_id == current_teacher.try(:id)
  end
end
