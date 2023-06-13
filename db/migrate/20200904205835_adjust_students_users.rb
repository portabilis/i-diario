class AdjustStudentsUsers < ActiveRecord::Migration[4.2]
  def change
    User.joins(user_roles: :role)
        .joins(:audits)
        .where(roles: { access_level: AccessLevel::STUDENT })
        .where(kind: RoleKind::STUDENT, student_id: nil)
        .where(audits: { action: 'create' })
        .select('users.*, audits.id AS audited_creation_id')
        .each do |user|
      next if user.roles.count > 1

      audited_creation = Audited::Audit.find(user.audited_creation_id)

      next unless (student_id = audited_creation.audited_changes['student_id'])

      user.without_auditing do
        user.update(student_id: student_id)
      end
    end
  end
end
