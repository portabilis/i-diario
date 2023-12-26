class AdjustStudentsUsersWithoutStudentId < ActiveRecord::Migration[4.2]
  def change
    User.joins(user_roles: :role)
        .joins(:audits)
        .where(audits: { action: 'create' })
        .where(roles: { access_level: AccessLevel::STUDENT })
        .where(kind: RoleKind::STUDENT, student_id: nil)
        .where("(SELECT COUNT(1)
                   FROM user_roles
                  WHERE user_roles.user_id = users.id) = 1")
        .select('users.*, audits.id AS audited_id')
        .each do |user|
          next unless (audited_creation = Audited::Audit.find_by(id: user.audited_id))
          next unless (email = audited_creation.audited_changes['email'])
          next unless email.end_with?('@ambiente.portabilis.com.br')
          next unless (api_code = email.split('@')[0])
          next unless (student = Student.find_by(api_code: api_code))

          user.without_auditing do
            user.update(student_id: student.id)
          end
        end
  end
end
