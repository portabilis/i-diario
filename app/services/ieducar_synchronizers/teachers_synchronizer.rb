class TeachersSynchronizer < BaseSynchronizer
  def synchronize!
    update_teachers(
      HashDecorator.new(
        api.fetch(
          ano: years.first
        )['servidores']
      )
    )
  end

  def self.synchronize_in_batch!(params)
    super do
      params[:years].each do |year|
        new(
          synchronization: params[:synchronization],
          worker_batch: params[:worker_batch],
          years: [year],
          entity_id: params[:entity_id]
        ).synchronize!
      end
    end
  end

  private

  def api_class
    IeducarApi::Teachers
  end

  def update_teachers(teachers)
    teachers.each do |teacher_record|
      Teacher.find_or_initialize_by(api_code: teacher_record.servidor_id).tap do |teacher|
        teacher.name = teacher_record.nome
        teacher.active = teacher_record.ativo == IeducarBooleanState::ACTIVE
        teacher.save! if teacher.changed?
      end
    end
  end
end
