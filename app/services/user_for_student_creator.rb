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
           .find_each do |student|
      next if User.find_by(student_id: student.id, kind: RoleKind::STUDENT)

      password = "estudante#{student.api_code}"
      login = User.find_by(login: student.api_code) ? '' : student.api_code

      User.find_or_initialize_by(
        login: login,
        email: "#{student.api_code}@ambiente.portabilis.com.br",
        kind: RoleKind::STUDENT,
        student_id: student.id
      ).tap do |user|
        user.first_name = student.name
        user.password = password
        user.password_confirmation = password
        user.status = UserStatus::ACTIVE

        new_record = user.new_record?

        user.save! if user.changed?

        next unless new_record

        user_role = UserRole.create!(
          user_id: user.id,
          role_id: role_id
        )

        user.update(current_user_role_id: user_role.id)
      end
    end
  end
end
