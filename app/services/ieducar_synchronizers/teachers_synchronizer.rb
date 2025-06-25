class TeachersSynchronizer < BaseSynchronizer
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
    teachers.each do |teacher_record|
      next if teacher_record.nome.blank?

      Teacher.with_discarded.find_or_initialize_by(api_code: teacher_record.servidor_id).tap do |teacher|
        teacher.name = teacher_record.nome
        teacher.active = teacher_record.ativo.to_s == IeducarBooleanState::ACTIVE
        teacher.save! if teacher.changed?
      end
    end
  end
end
