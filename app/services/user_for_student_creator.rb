class UserForStudentCreator
  def self.create!
    new.create!
  end

  def create!
    create_user
  end

  private

  def create_user
    role_id = Role.find_by(access_level: AccessLevel::STUDENT)&.id

    raise 'Permissão de aluno não encontrada.' if role_id.blank?

    Student.joins('LEFT JOIN users ON users.student_id = students.id')
           .where(users: { student_id: nil })
           .find_each(batch_size: 100) do |student|
      email = "#{student.api_code}@#{Rails.application.secrets[:STUDENT_DOMAIN]}"

      next if User.find_by(student_id: student.id, kind: RoleKind::STUDENT)
      next if User.find_by(email: email, kind: RoleKind::STUDENT)

      password = "estudante#{student.api_code}"
      login = User.find_by(login: student.api_code) ? '' : student.api_code

      user = User.find_or_initialize_by(
        login: login,
        email: email,
        kind: RoleKind::STUDENT,
        student_id: student.id
      )

      next unless user.new_record?

      user.first_name = student.name
      user.password = password
      user.password_confirmation = password
      user.status = UserStatus::ACTIVE
      user.save!

      user_role = UserRole.create!(
        user_id: user.id,
        role_id: role_id
      )

      user.current_user_role_id = user_role.id
      user.save!(validate: false)
    end
  end
end
