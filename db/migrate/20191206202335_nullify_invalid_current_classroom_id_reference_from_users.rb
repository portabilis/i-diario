class NullifyInvalidCurrentClassroomIdReferenceFromUsers < ActiveRecord::Migration[4.2]
  def change
    user_current_classroom_ids = User.pluck(:current_classroom_id).uniq.compact
    classroom_ids = Classroom.where(id: user_current_classroom_ids).pluck(:id).uniq

    not_found = user_current_classroom_ids - classroom_ids

    User.where(current_classroom_id: not_found).update_all(current_classroom_id: nil) if not_found.present?
  end
end
