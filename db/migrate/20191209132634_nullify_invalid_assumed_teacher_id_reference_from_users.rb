class NullifyInvalidAssumedTeacherIdReferenceFromUsers < ActiveRecord::Migration
  def change
    user_assumed_teacher_ids = User.pluck(:assumed_teacher_id).uniq.compact
    teacher_ids = Teacher.where(id: user_assumed_teacher_ids).pluck(:id).uniq

    not_found = user_assumed_teacher_ids - teacher_ids

    User.where(assumed_teacher_id: not_found).update_all(assumed_teacher_id: nil) if not_found.present?
  end
end
