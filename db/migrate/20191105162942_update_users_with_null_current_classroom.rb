class UpdateUsersWithNullCurrentClassroom < ActiveRecord::Migration[4.2]
  def change
    User.where(current_classroom_id: nil).each do |user|
      user.without_auditing do
        user.update(assumed_teacher_id: nil)
      end
    end
  end
end
