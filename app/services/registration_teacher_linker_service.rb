class RegistrationTeacherLinkerService
  def self.call(user)
    new.call(user)
  end

  def call(user)
    @user = user
    return unless @user&.cpf.present?

    teacher_data = fetch_teacher_from_api
    return unless teacher_data

    teacher = find_or_create_teacher(teacher_data)
    link_user_to_teacher(teacher) if teacher
  end

  private

  def fetch_teacher_from_api
    begin
      api_config = IeducarApiConfiguration.current
      return nil if api_config.new_record?

      api = IeducarApi::Teachers.new(api_config.to_api)
      response = api.fetch_by_cpf(@user.cpf)
      response['result']
    rescue => e
      Rails.logger.warn "Erro ao buscar servidor na API do iEducar para CPF #{@user.cpf}: #{e.message}"
      nil
    end
  end

  def find_or_create_teacher(teacher_data)
    return unless teacher_data['servidor_id'].present?

    Teacher.with_discarded.find_or_initialize_by(api_code: teacher_data['servidor_id']).tap do |teacher|
      teacher.name = teacher_data['nome']
      teacher.active = teacher_data['ativo'].to_s == IeducarBooleanState::ACTIVE

      if teacher.save
        Rails.logger.info "Professor #{teacher.id} criado/atualizado para o servidor_id #{teacher_data['servidor_id']}"
      else
        Rails.logger.warn "Falha ao salvar professor: #{teacher.errors.full_messages.join(', ')}"
        return nil
      end
    end
  end

  def link_user_to_teacher(teacher)
    return if @user.teacher_id == teacher.id

    unless active_with_teacher_discipline_classrooms?(teacher)
      Rails.logger.info "Teacher #{teacher.id} (#{teacher.name}) não possui vínculo com turmas."
      return
    end

    if teacher_already_linked_to_different_user?(teacher)
      Rails.logger.warn "Teacher #{teacher.id} (#{teacher.name}) já está vinculado a outro usuário."
      return
    end

    @user.teacher_id = teacher.id
    if @user.save(validate: false)
      Rails.logger.info "Usuário #{@user.id} (#{@user.name}) vinculado ao professor #{teacher.id} durante o registro"
    else
      Rails.logger.warn "Falha ao vincular usuário #{@user.id} ao professor #{teacher.id}: #{@user.errors.full_messages.join(', ')}"
    end
  end

  def teacher_already_linked_to_different_user?(teacher)
    existing_user = teacher.users.first
    existing_user.present? && existing_user.id != @user.id
  end

  def active_with_teacher_discipline_classrooms?(teacher)
    teacher.active? && teacher.teacher_discipline_classrooms.exists?
  end
end
