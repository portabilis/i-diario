module ContentRecordHelper
  def content_record_destroy?(content_record)
    content_record.teacher.id == current_teacher.try(:id) || current_user.current_role_is_admin_or_employee?
  end
end
