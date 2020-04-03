class PopulateTeacherProfilesByUsers < ActiveRecord::Migration
  def change
    User.where.not(teacher_id: nil).each do |user|
      TeacherProfile.generate(user)
    end

    User.where.not(teacher_id: nil).each do |user|
      user.teacher_profile_id = TeacherProfile.find_by(
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
end
