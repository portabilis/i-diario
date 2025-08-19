class UserTeacherLinkerService
  def self.call(teacher_records)
    new.call(teacher_records)
  end

  def call(teacher_records)
    @teacher_records = teacher_records
    teachers, users = load_teachers_and_users

    update_users_and_teachers(teachers, users)
  end

  def load_teachers_and_users
    teachers = Teacher.where(api_code: @teacher_records.map(&:servidor_id), active: true, discarded_at: nil)
                     .index_by { |t| t.api_code.to_s }
    
    users = User.joins(:user_roles).where(teacher_id: nil).distinct.index_by(&:cpf)
    
    [teachers, users]
  end

  def update_users_and_teachers(teachers, users)
    user_teacher_id_updates = []

    @teacher_records.each do |record|
      next if record.cpf.blank?

      user = users[record.cpf]
      teacher = teachers[record.servidor_id.to_s]

      next unless user && teacher

      user_teacher_id_updates << { user: user, teacher_id: teacher.id } if user.teacher_id != teacher.id
    end

    if user_teacher_id_updates.empty?
      Rails.logger.info 'Nenhum usuário encontrado para vinculação automática usuário-professor por CPF'
      return
    end

    User.transaction do
      user_teacher_id_updates.each do |user_teacher_id_update|
        user = user_teacher_id_update[:user]
        teacher_id = user_teacher_id_update[:teacher_id]

        if user.update(teacher_id: teacher_id)
          Rails.logger.info "Usuário #{user.id} (#{user.name}) vinculado ao professor #{teacher_id} pelo CPF"
        else
          Rails.logger.warn "Falha ao vincular usuário #{user.id}: #{user.errors.full_messages.join(', ')}"
        end
      end
    end
    
    Rails.logger.info 'Vinculação automática usuário-professor por CPF executada'
  end
end

