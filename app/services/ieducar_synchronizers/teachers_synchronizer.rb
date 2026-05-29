class TeachersSynchronizer < BaseSynchronizer
  MAX_RETRIES = 3

  def synchronize!
    update_teachers(
      HashDecorator.new(
        api.fetch['servidores']
      )
    )
  end

  private

  def api_class
    IeducarApi::Teachers
  end

  def update_teachers(teachers)
    preload_teachers(teachers.map(&:servidor_id))

    teachers.each do |teacher_record|
      next if teacher_record.nome.blank?

      retries = 0

      begin
        update_teacher_record(teacher_record)
      rescue ActiveRecord::RecordNotUnique => error
        raise error unless error.message.include?('api_code')

        retries += 1
        raise error if retries > MAX_RETRIES

        reset_record(:@teachers, teacher_record.servidor_id)
        retry
      end
    end

    UserTeacherLinkerService.call(teachers)
  end

  def update_teacher_record(teacher_record)
    (
      teacher(teacher_record.servidor_id) ||
      Teacher.new(api_code: teacher_record.servidor_id)
    ).tap do |teacher|
      teacher.name = teacher_record.nome
      teacher.active = teacher_record.ativo.to_s == IeducarBooleanState::ACTIVE
      teacher.save! if teacher.changed?
    end
  end
end
