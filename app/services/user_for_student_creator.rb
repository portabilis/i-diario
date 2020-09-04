class UserForStudentCreator
  def self.create!(student_id)
    new(student_id).create!
  end

  def initialize(student_id)
    @student = Student.find_by(id: student_id)
  end

  def create!
    create_user
  end

  private

  attr_accessor :student

  def create_user
    role_id = Role.find_by(access_level: 'student')&.id

    raise 'Permissão de aluno não encontrada.' if role_id.blank?

    return unless student
    return if User.find_by(login: student.api_code)
    return if User.find_by(student_id: student.id, kind: 'student')

    password = "estudante#{student.api_code}"

    user = User.create!(
      login: student.api_code,
      first_name: student.name,
      email: "#{student.api_code}@ambiente.portabilis.com.br",
      password: password,
      password_confirmation: password,
      status: 'active',
      kind: 'student',
      student_id: student.id
    )

    user_role = UserRole.create!(
      user_id: user.id,
      role_id: role_id
    )

    user.update(current_user_role_id: user_role.id)
  end
end
