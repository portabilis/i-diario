class NullifyInvalidAssumedTeacherIdReferenceFromUsers < ActiveRecord::Migration
  def change
    User.all.each do |user|
      assumed_teacher_id = user.assumed_teacher_id

      if assumed_teacher_id.present? && !Teacher.find_by(id: assumed_teacher_id)
        user.update(assumed_teacher_id: nil)
      end
    end
  end
end
