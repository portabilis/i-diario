class GenerateTeacherProfiles < ActiveRecord::Migration
  def change
    TeacherDisciplineClassroom.unscoped.kept.each(&:create_teacher_profile)

    User.where.not(
      teacher_id: nil,
      current_classroom_id: nil,
      current_school_year: nil,
      current_unity_id: nil,
      current_discipline_id: nil,
      teacher_profile_id: nil
    ).find_each do |user|
      user.teacher_profile_id = TeacherProfile.find_by(
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
