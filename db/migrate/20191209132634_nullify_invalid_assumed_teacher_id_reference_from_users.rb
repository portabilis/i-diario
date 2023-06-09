class NullifyInvalidAssumedTeacherIdReferenceFromUsers < ActiveRecord::Migration[4.2]
  class MigrationUser < ActiveRecord::Base
    self.table_name = :users
  end

  class MigrationTeacher < ActiveRecord::Base
    self.table_name = :teachers
  end

  def change
    user_assumed_teacher_ids = MigrationUser.pluck(:assumed_teacher_id).uniq.compact
    teacher_ids = MigrationTeacher.where(id: user_assumed_teacher_ids).pluck(:id).uniq

    not_found = user_assumed_teacher_ids - teacher_ids

    MigrationUser.where(assumed_teacher_id: not_found).update_all(assumed_teacher_id: nil) if not_found.present?
  end
end
