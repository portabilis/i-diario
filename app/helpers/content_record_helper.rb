module ContentRecordHelper
  def content_record_destroy?(content_record)
    content_record.teacher_id == current_teacher.try(:id) || current_user_role_is_employee_or_administrator?
  end
end
