class UserForStudentCreator
  def self.create!(student_id)
    new.create!(student_id)
  end

  def create!(student_id)
    student = Student.find(student_id)

    return if student.blank?

    create_user(student)
  end

  private

  def create_user(student)
    role_id = Role.find_by(access_level: AccessLevel::STUDENT)&.id

    raise 'Permissão de aluno não encontrada.' if role_id.blank?

    email = "#{student.api_code}@#{Rails.application.secrets[:STUDENT_DOMAIN]}"

    return if User.find_by(student_id: student.id, kind: RoleKind::STUDENT)
    return if User.find_by(email: email, kind: RoleKind::STUDENT)

    password = I18n.l(student.birth_date).tr('/', '') + student.api_code
    login = User.find_by(login: student.api_code) ? '' : student.api_code

    user = User.find_or_initialize_by(
      login: login,
      email: email,
      kind: RoleKind::STUDENT,
      student_id: student.id
    )

    return unless user.new_record?

    user.assign_attributes(first_name: student.name, password: password,
                           password_confirmation: password,
                           status: UserStatus::ACTIVE)

    user.user_roles.build(role_id: role_id)
    user.without_auditing do
      user.save!(validate: false)
    end
  end
end
