class UpdateUsersWithNullCurrentClassroom < ActiveRecord::Migration
  def change
    User.where(current_classroom_id: nil).each do |user|
      user.update(assumed_teacher_id: nil)
    end
  end
end
