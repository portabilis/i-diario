class UserTeacherLinkerService
  def self.call
    new.call
  end

  def call
    users = load_users_with_matching_cpf

    if users.empty?
      Rails.logger.info 'Nenhum usuário encontrado para vinculação automática usuário-professor por CPF'
      return
    end

    users_by_teacher = users.group_by(&:teacher_id)
    used_teacher_ids = load_used_teacher_ids

    update_users_and_teachers(users_by_teacher, used_teacher_ids)

    Rails.logger.info 'Vinculação automática usuário-professor por CPF executada'
  end

  private

  def load_users_with_matching_cpf
    User.joins(<<-SQL)
      INNER JOIN teachers ON
        REGEXP_REPLACE(users.cpf, '[^\\d]+', '', 'g') = REGEXP_REPLACE(teachers.cpf, '[^\\d]+', '', 'g')
        AND teachers.active = true
        AND teachers.discarded_at IS NULL
    SQL
        .where(teacher_id: nil)
        .where.not(cpf: [nil, ''])
        .select('users.id as user_id, teachers.id as teacher_id')
  end

  def load_used_teacher_ids
    User.where.not(teacher_id: nil).pluck(:teacher_id).to_set
  end

  def update_users_and_teachers(users_by_teacher, used_teacher_ids)
    User.transaction do
      users_by_teacher.each do |teacher_id, user_matches|
        next if used_teacher_ids.include?(teacher_id)

        first_user = user_matches.first
        user = User.find(first_user.user_id)

        next unless user_has_valid_roles?(user)

        if user.update(teacher_id: teacher_id)
          used_teacher_ids << teacher_id
          Rails.logger.info "Usuário #{user.id} (#{user.name}) vinculado ao professor #{teacher_id} pelo CPF"
        else
          Rails.logger.warn "Falha ao vincular usuário #{user.id}: #{user.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def user_has_valid_roles?(user)
    user.user_roles.any?
  end
end
