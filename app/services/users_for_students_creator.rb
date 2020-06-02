class UsersForStudentsCreator
  def self.create!(year)
    new(year).create!
  end

  def initialize(year)
    @year = year
  end

  def create!
    create_users_for_students(
      HashDecorator.new(
        api.fetch(
          escola: unities_api_code,
          ano: year,
          apenas_cursando: true
        )['alunos']
      )
    )
  end

  private

  attr_accessor :year

  def api
    IeducarApi::Students.new(IeducarApiConfiguration.first.to_api, true)
  end

  def unities_api_code
    Unity.with_api_code.pluck(:api_code).uniq
  end

  def create_users_for_students(students)
    role_id = Role.find_by(access_level: 'student')&.id

    raise 'Permissão de aluno não encontrada.' if role_id.blank?

    students.each do |student_record|
      next if User.find_by(login: student_record.aluno_id)
      next unless (student = Student.find_by(api_code: student_record.aluno_id))
      next if User.find_by(student_id: student.id, kind: 'student')

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
end
