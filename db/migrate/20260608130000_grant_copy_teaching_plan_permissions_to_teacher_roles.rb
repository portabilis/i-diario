class GrantCopyTeachingPlanPermissionsToTeacherRoles < ActiveRecord::Migration[5.0]
  COPY_FEATURES = %w[
    copy_discipline_teaching_plan
    copy_knowledge_area_teaching_plan
  ].freeze

  # Idempotente: role criado DEPOIS de a feature entrar no enum ja tem a linha
  # como DENIED -> vira CHANGE; criado ANTES nao tem linha -> insere como CHANGE;
  # re-run encontra CHANGE -> no-op. Roda em todos os tenants via db:migrate_dbs.
  def up
    Role.where(access_level: AccessLevel::TEACHER).find_each(batch_size: 100) do |role|
      COPY_FEATURES.each do |feature|
        role_permission = role.permissions.find_or_initialize_by(feature: feature)

        next if role_permission.permission == Permissions::CHANGE

        role_permission.permission = Permissions::CHANGE
        role_permission.save_without_auditing
      end
    end
  end

  # Inverso seguro: volta as duas features para DENIED (mantem a linha, preservando
  # o invariante "uma linha por feature" usado por Role#build_permissions!).
  def down
    Role.where(access_level: AccessLevel::TEACHER).find_each(batch_size: 100) do |role|
      role.permissions.where(feature: COPY_FEATURES).find_each do |role_permission|
        next if role_permission.permission == Permissions::DENIED

        role_permission.permission = Permissions::DENIED
        role_permission.save_without_auditing
      end
    end
  end
end
