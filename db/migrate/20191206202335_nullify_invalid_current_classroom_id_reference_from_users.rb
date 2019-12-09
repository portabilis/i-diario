class NullifyInvalidCurrentClassroomIdReferenceFromUsers < ActiveRecord::Migration
  def change
    User.all.each do |user|
      current_classroom_id = user.current_classroom_id

      if current_classroom_id.present? && !Classroom.find_by(id: current_classroom_id)
        user.update(current_classroom_id: nil)
      end
    end
  end
end
