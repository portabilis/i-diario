class ClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_classrooms(
      HashDecorator.new(
        api.fetch(
          escola_id: unity_api_code,
          ano: years.first
        )['turmas']
      )
    )
  end

  def self.synchronize_in_batch!(params)
    params[:filtered_by_unity] = true

    super do |unity_api_code|
      params[:years].each do |year|
        new(
          synchronization: params[:synchronization],
          worker_batch: params[:worker_batch],
          years: [year],
          unity_api_code: unity_api_code,
          entity_id: params[:entity_id]
        ).synchronize!
      end
    end
  end

  private

  def api_class
    IeducarApi::Classrooms
  end

  def update_classrooms(classrooms)
    classrooms.each do |classroom_record|
      Classroom.with_discarded.find_or_initialize_by(api_code: classroom_record.id).tap do |classroom|
        classroom.description = classroom_record.nome
        classroom.unity_id = unity(classroom_record.escola_id).try(:id)
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turno_id
        classroom.grade = grade(classroom_record.serie_id)
        classroom.year = classroom_record.ano
        classroom.save! if classroom.changed?

        classroom.discard_or_undiscard(classroom_record.deleted_at.present?)
      end
    end
  end
end
