class PopulateTeacherProfilesByUsers < ActiveRecord::Migration
  def up
    User.where.not(teacher_id: nil).find_each do |user|
      TeacherProfile.generate(user)
    end

    User.where.not(teacher_id: nil).find_each do |user|
      user.teacher_profile_id = TeacherProfile.find_by(
        user_role_id: user.current_user_role_id,
        user_id: user.id,
        teacher_id: user.teacher_id,
        classroom_id: user.current_classroom_id,
        year: user.current_school_year,
        unity_id: user.current_unity_id,
        discipline_id: user.current_discipline_id
      ).try(:id)
      user.save! if user.teacher_profile_id
    end
  end

  def down
    User.update_all(teacher_profile_id: nil)
    TeacherProfile.delete_all
  end
end
